require 'bundler'
Bundler.require

Dotenv.load

require File.expand_path('app')
run App.new
