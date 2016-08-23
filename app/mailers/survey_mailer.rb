# frozen_string_literal: true
class SurveyMailer < ApplicationMailer
  def self.send_notification(notification)
    return unless Features.email?
    user_role = notification.survey_assignment.courses_user_role
    case user_role
    when CoursesUsers::Roles::INSTRUCTOR_ROLE
      instructor_survey_notification(notification).deliver_now
    when CoursesUsers::Roles::STUDENT_ROLE
      student_learning_preassessment_notification(notification).deliver_now
    else
      raise StandardError, 'Unknown survey type!'
    end
  end

  def self.send_follow_up(notification)
    return unless Features.email?
    user_role = notification.survey_assignment.courses_user_role
    case user_role
    when CoursesUsers::Roles::INSTRUCTOR_ROLE
      instructor_survey_follow_up(notification).deliver_now
    when CoursesUsers::Roles::STUDENT_ROLE
      student_learning_preassessment_follow_up(notification).deliver_now
    else
      raise StandardError, 'Unknown survey type!'
    end
  end

  def instructor_survey_notification(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "A survey is available for your course, '#{@course.title}'")
  end

  def instructor_survey_follow_up(notification)
    set_ivars(notification)
    mail(to: @user.email,
         subject: "Reminder: A survey is available for your course, '#{@course.title}'")
  end

  def student_learning_preassessment_notification(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "Take our assessment!")
  end

  def student_learning_preassessment_follow_up(notification)
    set_ivars(notification)
    mail(to: @user.email, subject: "Reminder: Take our assessment!")
  end

  private

  def set_ivars(notification)
    @notification = notification
    @user = notification.user
    @survey = notification.survey
    @course = notification.course
  end
end
