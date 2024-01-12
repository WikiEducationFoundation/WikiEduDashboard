# frozen_string_literal: true
require_dependency Rails.root.join('lib/analytics/campaign_csv_builder')
require_dependency Rails.root.join('app/workers/csv_cleanup_worker')

class CampaignCsvWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.generate_csv(campaign:, filename:, type:, include_course:)
    perform_async(campaign.id, filename, type, include_course)
  end

  def perform(campaign_id, filename, type, include_course)
    campaign = Campaign.find(campaign_id)
    builder = CampaignCsvBuilder.new(campaign)
    data = to_csv(type, campaign, builder, include_course)

    write_csv(filename, data)
    CsvCleanupWorker.perform_at(1.week.from_now, filename)
  end

  def to_csv(type, campaign, builder, include_course)
    case type
    when 'instructors'
      campaign.users_to_csv(:instructors, course: include_course)
    when 'students'
      campaign.users_to_csv(:students, course: include_course)
    when 'courses'
      builder.courses_to_csv
    when 'articles'
      builder.articles_to_csv
    when 'revisions'
      builder.revisions_to_csv
    when 'wikidata'
      builder.wikidata_to_csv
    end
  end

  private

  def write_csv(filename, data)
    FileUtils.mkdir_p "public#{CampaignsController::CSV_PATH}"
    File.write "public#{CampaignsController::CSV_PATH}/#{filename}", data
  end
end
