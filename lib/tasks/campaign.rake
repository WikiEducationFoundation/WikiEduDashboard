# frozen_string_literal: true

namespace :campaign do
  desc 'Add new campaigns from application.yml'
  task add_campaigns: :environment do
    Rails.logger.debug 'Adding new campaigns (if there are any to add)'
    Campaign.initialize_campaigns
  end
end
