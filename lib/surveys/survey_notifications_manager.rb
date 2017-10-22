# frozen_string_literal: true

class SurveyNotificationsManager
  def self.create_notifications(survey_assignments=nil)
    survey_assignments ||= SurveyAssignment.published
    survey_assignments.each do |survey_assignment|
      new(survey_assignment).create_notifications_for_assignment
    end
  end

  def initialize(survey_assignment)
    @survey_assignment = survey_assignment
  end

  def create_notifications_for_assignment
    @survey_assignment.courses_users_ready_for_survey.each do |courses_user|
      build_notifications_for_(courses_user)
    end
  end

  private

  def build_notifications_for_(courses_user)
    return if any_existing_notifications_for_user?(courses_user)
    notification = SurveyNotification.new(
      courses_users_id: courses_user.id,
      survey_assignment_id: @survey_assignment.id,
      course_id: courses_user.course_id
    )
    notification.save
  end

  def any_existing_notifications_for_user?(courses_user)
    all_courses_users_ids = courses_user.user.courses_users.pluck(:id)
    SurveyAssignment.by_courses_user_and_survey(
      courses_users_id: all_courses_users_ids,
      survey_id: @survey_assignment.survey_id
    ).any?
  end
end
