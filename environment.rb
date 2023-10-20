# frozen_string_literal: true

require 'bundler'

ENV['RACK_ENV'] ||= 'development'
Bundler.require(:default, ENV['RACK_ENV'].to_sym)

require 'pathname'
APP_ROOT = Pathname.new(File.expand_path('.', __dir__)).freeze

require './app'
