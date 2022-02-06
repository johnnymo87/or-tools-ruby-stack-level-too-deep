# frozen_string_literal: true

module Demo
  module Models
    # This object wraps a row in the bins CSV file.
    class Bin < Dry::Struct
      CSV_PATH = File.expand_path('./bins.csv', __dir__)

      transform_keys(&:to_sym)

      attribute :display_name, Types::String
      attribute :volume, Types::Coercible::Integer
      attribute :cost, Types::Coercible::Integer
      attribute :items?, Types::Array.of(Item)

      def hash_key
        @hash_key ||= "#{display_name} (#{SecureRandom.uuid})"
      end

      def self.load_from_csv
        CSV.parse(File.read(CSV_PATH), headers: true).map(&method(:new))
      end
    end
  end
end
