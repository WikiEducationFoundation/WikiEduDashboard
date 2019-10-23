# frozen_string_literal: true

class TermRecapMailerPreview < ActionMailer::Preview
  def email_to_instructors
    TermRecapMailer.send_recap(example_course, Campaign.default_campaign)
  end

  private

  def example_course
    Course.where('revision_count > 20').first
  end
end
