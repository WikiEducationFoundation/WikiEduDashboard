# frozen_string_literal: true

# == Schema Information
#
# Table name: survey_notifications
#
#  id                     :integer          not null, primary key
#  courses_users_id       :integer
#  course_id              :integer
#  survey_assignment_id   :integer
#  dismissed              :boolean          default(FALSE)
#  email_sent_at          :datetime
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  completed              :boolean          default(FALSE)
#  last_follow_up_sent_at :datetime
#  follow_up_count        :integer          default(0)
#

class SurveyNotification < ApplicationRecord
  belongs_to :courses_user, class_name: 'CoursesUsers'
  belongs_to :survey_assignment
  belongs_to :course

  scope :completed, -> { where(completed: true) }
  scope :dismissed, -> { where(dismissed: true) }

  def self.active
    unclosed_survey_ids = Survey.where(closed: false).pluck(:id)
    unclosed_survey_assignment_ids = SurveyAssignment.where(survey_id: unclosed_survey_ids)
                                                     .pluck(:id)
    where(dismissed: false,
          completed: false,
          survey_assignment_id: unclosed_survey_assignment_ids)
  end

  def self.email_enabled
    emailable_survey_assignment_ids = SurveyAssignment.where(send_email: true).pluck(:id)

    where(survey_assignment_id: emailable_survey_assignment_ids)
  end
  ####################
  # Instance methods #
  ####################

  # This should return something falsey if no email was sent, and something
  # truthy if an email was sent. SurveyUpdate relies on this behavior.
  def send_email
    # In these environments only send emails to the users specified in ENV['survey_test_email']
    return if nonsafe_email_environment?
    return if email_sent_at.present?
    return if user.email.nil?
    SurveyMailer.send_notification(self)
    update_attribute(:email_sent_at, Time.zone.now)
  rescue Mailgun::CommunicationError => e
    Sentry.capture_exception e, extra: { username: user.username,
                                         email: user.email,
                                         survey_notification_id: id }
  end

  # This should return something falsey if no email was sent, and something
  # truthy if an email was sent. SurveyUpdate relies on this behavior.
  def send_follow_up
    return unless survey_assignment.follow_up_days_after_first_notification.present?
    return if user.email.nil?
    return unless ready_for_follow_up?
    SurveyMailer.send_follow_up(self)
    update(last_follow_up_sent_at: Time.zone.now,
           follow_up_count: follow_up_count + 1)
  end

  def survey
    survey_assignment.survey
  end

  def user
    CoursesUsers.find(courses_users_id).user
  end

  def course
    Course.find(course_id)
  end

  private

  def nonsafe_email_environment?
    %w[development staging].include?(Rails.env) &&
      ENV['survey_test_email'].split(',').exclude?(user.email)
  end

  MAX_FOLLOW_UPS = 3
  def ready_for_follow_up?
    return false if email_sent_at.nil?
    return false if Time.zone.now < last_email_sent_at + time_before_another_email
    return false if follow_up_count >= MAX_FOLLOW_UPS
    true
  end

  def time_before_another_email
    survey_assignment.follow_up_days_after_first_notification.days
  end

  def last_email_sent_at
    last_follow_up_sent_at.presence || email_sent_at
  end
end
