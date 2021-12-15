# frozen_string_literal: true

# Automates sending term recap emails to each course after it ends.
class TermRecapEmailScheduler
  def self.schedule_emails
    return unless Features.wiki_ed?
    new.schedule_term_recap_emails
  end

  def schedule_term_recap_emails
    courses_to_email.each do |course|
      campaign = student_program_campaign(course)
      next unless campaign
      TermRecapEmailWorker.send_email(course: course, campaign: campaign)
    end
  end

  private

  DAYS_WITHIN_COURSE_END_TO_EMAIL = 7

  def recently_ended_courses
    Course.current.ended
          .where('end > ?', DAYS_WITHIN_COURSE_END_TO_EMAIL.days.ago)
          .includes(:campaigns)
  end

  def courses_to_email
    recently_ended_courses.select do |course|
      course.flags[:recap_sent_at].nil?
    end
  end

  def student_program_campaign(course)
    course.campaigns.detect { |campaign| student_program_campaign?(campaign.slug) }
  end

  # We only want to send recaps for Student program courses, which
  # are in campaigns like "spring_2021" or "summer_2023"
  STUDENT_PROGRAM_CAMPAIGN_MATCHER = /(^spring|fall|summer)_202.$/.freeze
  def student_program_campaign?(campaign_slug)
    campaign_slug.match?(STUDENT_PROGRAM_CAMPAIGN_MATCHER)
  end
end
