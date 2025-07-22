# frozen_string_literal: true

require "#{Rails.root}/setup/populate_tickets"

namespace :dev do
  desc 'Set up some example tickets'
  task populate_tickets: :environment do
    populate_tickets_demo
  end
end
