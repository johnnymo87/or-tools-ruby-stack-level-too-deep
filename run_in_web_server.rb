# frozen_string_literal: true

require 'sinatra'
require 'sinatra/json'
require_relative 'lib/demo'

set :bind, '0.0.0.0'

get '/' do
  json Demo.run
end
