# frozen_string_literal: true

namespace :dev do
  desc 'Set up some example tickets'
  task populate_tickets: :environment do
    # Required here rather than at the top of the file, because loading the
    # tasks (which SurveyAssignmentsController does) would otherwise load
    # Faker, whose locale files add a stray `pt-BR` to I18n.available_locales.
    require "#{Rails.root}/setup/populate_tickets"
    populate_tickets_demo
  end
end
