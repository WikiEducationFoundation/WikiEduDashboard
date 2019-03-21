# frozen_string_literal: true

require "#{Rails.root}/setup/populate_dashboard"
require "#{Rails.root}/setup/populate_tickets"

namespace :dev do
  desc 'Set up some example data'
  task populate: :environment do
    populate_dashboard
  end

  desc 'Set up example course with associated ticketing'
  task ticketing: :environment do
    populate_tickets_demo
  end
end
