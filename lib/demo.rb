# frozen_string_literal: true

%w[
  csv
  dry-struct
  json
  or-tools
  zeitwerk
].each(&method(:require))

module Demo
  module Types
    include Dry.Types()
  end

  def self.run
    Solver
      .solve(
        bins: Models::Bin.load_from_csv,
        items: Models::Item.load_from_csv
      )
      .map(&:to_h)
  end
end

Zeitwerk::Loader
  .for_gem
  .tap(&:setup)
  .tap(&:eager_load)
