class SurveyAssignment < ActiveRecord::Base
  belongs_to :survey
  has_and_belongs_to_many :cohorts
  has_many :survey_notifications

  scope :published, -> { where(published:true)}

  def send_at
    {
      :days => send_date_days,
      :before => send_before,
      :relative_to => send_date_relative_to
    }
  end

  def courses_users_ready_for_survey
    courses = courses_with_pending_notifications
    courses.collect {|course| course.courses_users.where({ role: courses_user_role})}.flatten
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
end
