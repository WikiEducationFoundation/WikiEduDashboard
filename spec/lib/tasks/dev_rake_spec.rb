# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/constant_update"

# https://robots.thoughtbot.com/test-rake-tasks-like-a-boss

describe 'dev:populate' do
  include_context 'rake'

  describe 'database population script' do
    skip 'runs without error and leaves the database in a good state' do
      VCR.use_cassette 'populate_database' do
        rake['dev:populate'].invoke
        ConstantUpdate.new
      end
    end
  end
end
