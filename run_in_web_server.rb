require 'bundler/setup'
Bundler.require

set :bind, '0.0.0.0'

get '/' do
  bins = [
    ['Bin 0', 3000, 1373],
    ['Bin 1', 1768, 633],
    ['Bin 2', 1000, 1028],
    ['Bin 3', 886, 633],
    ['Bin 4', 1660, 1028],
    ['Bin 5', 3000, 3000],
    ['Bin 6', 3000, 1373],
    ['Bin 7', 3000, 1028],
    ['Bin 8', 3000, 633],
    ['Bin 9', 2242, 633]
  ].map { |name, volume, cost| { name:, volume:, cost: } }

  items = [
    ['Item 0', 656],
    ['Item 1', 431],
    ['Item 2', 721],
    ['Item 3', 849],
    ['Item 4', 117],
    ['Item 5', 940],
    ['Item 6', 1302],
    ['Item 7', 547],
    ['Item 8', 645],
    ['Item 9', 757]
  ].map { |name, volume| { name:, volume: } }

  solver = ORTools::Solver.new('demo', :cbc)

  # Variables
  # item_in_bin_vars[item][bin]
  # * 1 if an item is packed in a bin.
  # * 0 otherwise.
  item_in_bin_vars = items.each_with_object({}) do |item, item_hash|
    item_hash[item[:name]] = bins.each_with_object({}) do |bin, bin_hash|
      bin_hash[bin[:name]] =
        solver.int_var(0, 1, [item[:name], bin[:name]].join(' in '))
    end
  end

  # Variables
  # bin_vars[bin]
  # * 0 <= number of times bin is used <= 1
  bin_vars = bins.each_with_object({}) do |bin, hash|
    hash[bin[:name]] = solver.int_var(0, 1, bin[:name])
  end

  # Constraints
  # Each item must be in exactly one bin.
  # This constraint is set by requiring that the sum of item_in_bin_vars[item, bin]
  # over all bins is equal to 1.
  items.each do |item|
    solver.add(solver.sum(item_in_bin_vars.fetch(item[:name]).values) == 1)
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
  bins.each do |bin|
    solver.add(
      solver.sum(
        items.map do |item|
          item_in_bin_vars.fetch(item[:name]).fetch(bin[:name]) * item[:volume]
        end
      ) <=
      bin_vars.fetch(bin[:name]) * bin[:volume]
    )
  end

  # In order to minimize the number of bins while ALSO minimizing other
  # factors, I'm using a bin_count_penalty that is as large as the largest
  # value of the largest of the other two factors.
  bin_count_penalty = [bins.map { _1[:cost] }.max, bins.map { _1[:volume] }.max].max

  # Define what we're trying to minimize:
  # * Number of boxes
  # * Total cost
  # * Total volume
  solver.minimize(
    solver.sum(
      bins.map { |bin| bin_vars.fetch(bin[:name]) * bin_count_penalty } +
      bins.map { |bin| bin_vars.fetch(bin[:name]) * bin[:cost] } +
      bins.map { |bin| bin_vars.fetch(bin[:name]) * bin[:volume] }
    )
  )

  # Attempt to solve the problem. Return a list of bins chosen by the solver,
  # each with their chosen items inside. If a solution cannot be found, abort.
  status = solver.solve
  raise 'Huh?' unless status == :optimal

  bins
    .flat_map do |bin|
      next if bin_vars.fetch(bin[:name]).solution_value.to_i.zero?

      items_in_bin = items.reject do |item|
        item_in_bin_vars.fetch(item[:name]).fetch(bin[:name]).solution_value.zero?
      end

      bin.to_h.merge(items: items_in_bin.map(&:to_h))
    end
    .compact
    .map(&:to_h)
    .to_s
end
