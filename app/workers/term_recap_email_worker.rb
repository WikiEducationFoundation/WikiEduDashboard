# frozen_string_literal: true

class TermRecapEmailWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  retry: 0 # Move job to the 'dead' queue if it fails

  def self.send_email(course:, campaign:)
    perform_async(course.id, campaign.id)
  end

  def perform(course_id, campaign_id)
    course = Course.find(course_id)
    campaign = Campaign.find(campaign_id)

    TermRecapMailer.send_recap(course, campaign)

    course.flags[:recap_sent_at] = Time.now.utc
    course.save
  end
end
