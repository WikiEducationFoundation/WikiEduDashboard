# frozen_string_literal: true

class TermRecapMailerPreview < ActionMailer::Preview
  DESCRIPTION = 'End-of-term summary emails sent to instructors after their course finishes.'
  METHOD_DESCRIPTIONS = {
    email_to_instructors: 'Full recap with stats for courses with strong student contributions',
    basic_email_to_instructors: 'Shorter recap for courses with lower average word counts'
  }.freeze

  def email_to_instructors
    TermRecapMailer.email(example_course, Campaign.default_campaign)
  end

  def basic_email_to_instructors
    TermRecapMailer.basic_email(example_course, Campaign.default_campaign)
  end

  private

  def example_course
    Course.new(
      title: 'Advanced Topics in Global Health',
      slug: 'Global_Health/Advanced_Topics_(Spring_2025)',
      school: 'University of Maryland',
      expected_students: 24,
      user_count: 22,
      start: 3.months.ago,
      end: 1.month.from_now,
      revision_count: 450
    )
  end
end
