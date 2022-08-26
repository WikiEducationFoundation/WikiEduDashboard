# frozen_string_literal: true

class TermRecapMailerPreview < ActionMailer::Preview
  def email_to_instructors
    TermRecapMailer.email(example_course, Campaign.default_campaign)
  end

  def basic_email_to_instructors
    TermRecapMailer.basic_email(example_course, Campaign.default_campaign)
  end

  private

  def example_course
    Course.nonprivate.where('revision_count > 20').first
  end
end
