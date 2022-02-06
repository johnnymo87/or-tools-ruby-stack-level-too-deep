# frozen_string_literal: true

require_relative 'lib/demo'

puts JSON.pretty_generate(Demo.run)
