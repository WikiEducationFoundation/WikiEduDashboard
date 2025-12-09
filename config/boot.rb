# Set up gems listed in the Gemfile.
require 'logger'
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exist?(ENV['BUNDLE_GEMFILE'])
require 'bootsnap/setup'
