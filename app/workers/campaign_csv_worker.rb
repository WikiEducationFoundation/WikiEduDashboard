# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/analytics/campaign_csv_builder"

class CampaignCsvWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.generate_csv(campaign:, filename:, type:)
    perform_async(campaign.id, filename, type)
  end

  CSV_PATH = 'public/system/analytics'

  def perform(campaign_id, filename, type)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign)
    data = case type
           when 'courses'
             builder.courses_to_csv
           when 'articles'
             builder.articles_to_csv
           when 'revisions'
             builder.revisions_to_csv
           end

    File.write "#{CSV_PATH}/#{filename}", data
    # TODO: schedule deletion of file 1 week later
  end
end
