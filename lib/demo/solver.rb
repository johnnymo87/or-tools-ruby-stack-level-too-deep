# frozen_string_literal: true

module Demo
  # This is a demo of a "bin packing" problem:
  # https://developers.google.com/optimization/bin/bin_packing.
  #
  # We need to pack a set of items into some bins. There are many bins to choose
  # from. Items and bins both have volumes, and bins also have costs.
  #
  # We are going to try to minimize the total number of bins chosen AND their
  # total cost AND their total volume.
  class Solver
    # @param [Enumerable<Models::Bin>] bins
    # @param [Enumerable<Models::Item>] items
    #
    # Attempt to solve the problem. Return an enumerable of bins chosen by the
    # solver, each with their chosen items inside.
    #
    # @raise [UnsolvableError] If an optimal split cannot be found, abort.
    #
    # @return [Enumerable<Models::Bin>]
    def self.solve(bins:, items:)
      new(bins:, items:).solve
    end

    # @param [Enumerable<Models::Bin>] bins
    # @param [Enumerable<Models::Item>] items
    def initialize(bins:, items:)
      @bins = bins
      @items = items
    end

    # Attempt to solve the problem. Return an enumerable of bins chosen by the
    # solver, each with their chosen items inside.
    #
    # @raise [UnsolvableError] If an optimal split cannot be found, abort.
    #
    # @return [Enumerable<Models::Bin>]
    def solve
      each_item_must_be_in_exactly_one_bin
      the_amount_packed_into_each_bin_cannot_exceed_its_capacity
      set_objective
      run_solver
    end

    private

    attr_reader :bins, :items

    def solver
      @solver ||= ORTools::Solver.new('demo', :cbc)
    end

    # Variables
    # item_in_bin_vars[item][bin]
    # * 1 if an item is packed in a bin.
    # * 0 otherwise.
    #
    # return [Hash<String, Hash<String, ???>>]
    def item_in_bin_vars
      @item_in_bin_vars ||= items.each_with_object({}) do |item, item_hash|
        item_hash[item.hash_key] = bins.each_with_object({}) do |bin, bin_hash|
          bin_hash[bin.hash_key] =
            solver.int_var(0, 1, [item.hash_key, bin.hash_key].join(' in '))
        end
      end
    end

    # Variables
    # bin_vars[bin]
    # * 0 <= number of times bin is used <= 1
    #
    # return [Hash<String, ???>]
    def bin_vars
      @bin_vars ||= bins.each_with_object({}) do |bin, hash|
        hash[bin.hash_key] = solver.int_var(0, 1, bin.hash_key)
      end
    end

    # Constraints
    # Each item must be in exactly one bin.
    # This constraint is set by requiring that the sum of item_in_bin_vars[item, bin]
    # over all bins is equal to 1.
    def each_item_must_be_in_exactly_one_bin
      items.each do |item|
        solver.add(solver.sum(item_in_bin_vars.fetch(item.hash_key).values) == 1)
      end
    end

    # Constraints
    # The amount packed into each bin cannot exceed its capacity.
    #
    # Why use multiplication? Because our bin variables' values are either 1 or
    # 0, based on whether or not they're used. For example, let's say we have a
    # bin whose volume is 1000.
    #
    # If the bin is used, then we constrain
    #   the sum of its items' volumes to <= (1 * 1000).
    # Otherwise, we constrain
    #   the sum of its items' volumes to <= (0 * 1000).
    def the_amount_packed_into_each_bin_cannot_exceed_its_capacity
      bins.each do |bin|
        solver.add(
          solver.sum(
            items.map do |item|
              item_in_bin_vars.fetch(item.hash_key).fetch(bin.hash_key) * item.volume
            end
          ) <=
          bin_vars.fetch(bin.hash_key) * bin.volume
        )
      end
    end

    # In order to minimize the number of bins while ALSO minimizing other
    # factors, I'm using a bin_count_penalty that is as large as the largest
    # value of the largest of the other two factors.
    def bin_count_penalty
      @bin_count_penalty ||= [bins.map(&:cost).max, bins.map(&:volume).max].max
    end

    # Define what we're trying to minimize:
    # * Number of boxes
    # * Total cost
    # * Total volume
    def set_objective
      solver.minimize(
        solver.sum(
          bins.map { |bin| bin_vars.fetch(bin.hash_key) * bin_count_penalty } +
          bins.map { |bin| bin_vars.fetch(bin.hash_key) * bin.cost } +
          bins.map { |bin| bin_vars.fetch(bin.hash_key) * bin.volume }
        )
      )
    end

    # Attempt to solve the problem. Return an enumerable of bins chosen by the
    # solver, each with their chosen items inside.
    #
    # @raise [UnsolvableError] If an optimal split cannot be found, abort.
    #
    # @return [Enumerable<Models::Bin>]
    def run_solver
      status = solver.solve
      raise UnsolvableError.new(bins:, items:, status:) unless status == :optimal

      bins.flat_map do |bin|
        next if bin_vars.fetch(bin.hash_key).solution_value.to_i.zero?

        items_in_bin = items.reject do |item|
          item_in_bin_vars.fetch(item.hash_key).fetch(bin.hash_key).solution_value.zero?
        end

        bin.class.new(bin.to_h.merge(items: items_in_bin))
      end.compact
    end
  end
end
