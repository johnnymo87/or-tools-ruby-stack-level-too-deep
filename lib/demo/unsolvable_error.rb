# frozen_string_literal: true

module Demo
  # If there's a problem and we cannot solve the optimization problem, we use
  # this error class to throw an error with a helpful message.
  class UnsolvableError < StandardError
    # @param [Enumerable<Models::Bin>] bins
    # @param [Enumerable<Models::Item>] items
    # @param [Symbol] status
    def initialize(bins:, items:, status:)
      super()
      @bins = bins
      @items = items
      @status = status
    end

    def message
      <<~MSG
        Unable to solve the problem!

        Status: #{status}

        Bins considered:
        #{JSON.pretty_generate(bins.map(&:to_h))}

        Items considered:
        #{JSON.pretty_generate(items.map(&:to_h))}
      MSG
    end

    private

    attr_reader :bins, :items, :status
  end
end
