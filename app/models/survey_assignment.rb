class SurveyAssignment < ActiveRecord::Base
  belongs_to :survey
  has_and_belongs_to_many :cohorts
  has_many :survey_notifications

  before_destroy :remove_notifications

  scope :published, -> { where(published: true) }
  scope :by_survey, -> (survey_id) { where(survey_id: survey_id) }

  def self.by_courses_user_and_survey(options)
    survey_id, courses_user_id = options.values_at(:survey_id, :courses_user_id)
    by_survey(survey_id).includes(:survey_notifications).where(
      survey_notifications: { courses_user_id: courses_user_id }
    )
  end

  def send_at
    {
      days: send_date_days,
      before: send_before,
      relative_to: send_date_relative_to
    }
  end

  def total_notifications
    users = cohorts.collect do |c|
      c.courses.collect do |course|
        course.courses_users.where(role: courses_user_role)
      end
    end
    users.flatten.length
  end

  def courses_users_ready_for_survey
    courses = courses_with_pending_notifications.collect do |course|
      course.courses_users.where(role: courses_user_role)
    end
    courses.flatten
  end

  def survey
    Survey.find(survey_id)
  end

  def active?
    published && !courses_with_pending_notifications.empty?
  end

  def courses_with_pending_notifications
    cohorts.collect { |cohort| cohort.courses.will_be_ready_for_survey(send_at) }.flatten
  end

  def status
    return 'Draft' unless published
    return 'Nil' if total_notifications == 0
    return 'Pending' if total_notifications == 0
    return 'Active' if total_notifications > 0
    return 'Closed' if survey.closed
  end

  private

  def remove_notifications
    SurveyNotification.where(survey_assignment_id: id).destroy_all
  end
end
