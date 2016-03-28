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
    courses = self.cohorts.collect { |cohort| cohort.courses.ready_for_survey(send_at) }.flatten
    courses.collect {|course| course.courses_users.where({ role: courses_user_role})}.flatten
  end
end
