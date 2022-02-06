# frozen_string_literal: true

module Demo
  module Models
    # This object wraps a row in the items CSV file.
    class Item < Dry::Struct
      CSV_PATH = File.expand_path('./items.csv', __dir__)

      transform_keys(&:to_sym)

      attribute :display_name, Types::String
      attribute :volume, Types::Coercible::Integer

      def hash_key
        @hash_key ||= "#{display_name} (#{SecureRandom.uuid})"
      end

      def self.load_from_csv
        CSV.parse(File.read(CSV_PATH), headers: true).map(&method(:new))
      end
    end
  end
end
