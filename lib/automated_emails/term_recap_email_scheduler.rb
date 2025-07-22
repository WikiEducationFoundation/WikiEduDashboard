# frozen_string_literal: true

# Automates sending term recap emails to each course after it ends.
class TermRecapEmailScheduler
  def self.schedule_emails
    return unless Features.wiki_ed?
    new.schedule_term_recap_emails(recently_ended_courses)
  end

  def schedule_term_recap_emails(courses)
    eligible_courses(courses).each do |course|
      campaign = student_program_campaign(course)
      next unless campaign
      TermRecapEmailWorker.send_email(course:, campaign:)
    end
  end

  DAYS_WITHIN_COURSE_END_TO_EMAIL = 7

  def self.recently_ended_courses
    Course.current.ended
          .where('end > ?', DAYS_WITHIN_COURSE_END_TO_EMAIL.days.ago)
          .includes(:campaigns)
  end

  private

  def eligible_courses(courses)
    courses.select do |course|
      should_email?(course)
    end
  end

  def student_program_campaign(course)
    course.campaigns.detect { |campaign| student_program_campaign?(campaign.slug) }
  end

  # We only want to send recaps for Student program courses, which
  # are in campaigns like "spring_2021" or "summer_2023"
  STUDENT_PROGRAM_CAMPAIGN_MATCHER = /(^spring|fall|summer)_202.$/
  def student_program_campaign?(campaign_slug)
    campaign_slug.match?(STUDENT_PROGRAM_CAMPAIGN_MATCHER)
  end

  def should_email?(course)
    return false if course.average_word_count.zero? # Did some work?
    return false if course.flags[:recap_sent_at].present? # Recap not already sent?
    return false if course.withdrawn # Not withdrawn?
    true
  end
end
