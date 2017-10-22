# frozen_string_literal: true

# == Schema Information
#
# Table name: survey_assignments
#
#  id                                      :integer          not null, primary key
#  courses_user_role                       :integer
#  created_at                              :datetime         not null
#  updated_at                              :datetime         not null
#  send_date_days                          :integer
#  survey_id                               :integer
#  send_before                             :boolean          default(TRUE)
#  send_date_relative_to                   :string(255)
#  published                               :boolean          default(FALSE)
#  notes                                   :text(65535)
#  follow_up_days_after_first_notification :integer
#  send_email                              :boolean
#  email_template                          :string(255)
#  custom_email                            :text(65535)
#

class SurveyAssignment < ActiveRecord::Base
  has_paper_trail
  belongs_to :survey
  has_and_belongs_to_many :campaigns
  has_many :survey_notifications

  before_destroy :remove_notifications

  scope :published, -> { where(published: true) }
  scope :by_survey, ->(survey_id) { where(survey_id: survey_id) }

  def self.by_courses_user_and_survey(options)
    survey_id, courses_users_id = options.values_at(:survey_id, :courses_users_id)
    by_survey(survey_id).includes(:survey_notifications).where(
      survey_notifications: { courses_users_id: courses_users_id }
    )
  end

  ###########################
  # Custom email attributes #
  ###########################
  serialize :custom_email, Hash

  def custom_email_subject
    custom_email[:subject]
  end

  def custom_email_headline
    custom_email[:headline]
  end

  def custom_email_body
    custom_email[:body]
  end

  def custom_email_signature
    custom_email[:signature]
  end

  ##############################
  # Custom notification banner #
  ##############################
  def custom_banner_message
    # This is stored within custom_email for convenience.
    custom_email[:banner_message]
  end

  ####################
  # Instance methods #
  ####################
  def send_at
    {
      days: send_date_days,
      before: send_before,
      relative_to: send_date_relative_to
    }
  end

  def total_notifications
    users = campaigns.collect do |c|
      c.courses.collect do |course|
        course.courses_users.where(role: courses_user_role)
      end
    end
    users.flatten.length
  end

  def courses_users_ready_for_survey
    courses = courses_users_ready_for_notifications.collect do |course|
      course.courses_users.where(role: courses_user_role)
    end
    courses.flatten
  end

  def survey
    Survey.find_by_id(survey_id)
  end

  def active?
    published && !courses_with_pending_notifications.empty?
  end

  def courses_users_ready_for_notifications
    campaigns.collect { |campaign| campaign.courses.ready_for_survey(send_at) }.flatten
  end

  def courses_with_pending_notifications
    campaigns.collect { |campaign| campaign.courses.will_be_ready_for_survey(send_at) }.flatten
  end

  def target_courses
    campaigns.collect(&:courses).flatten
  end

  def target_user_count
    target_courses.sum { |c| c.courses_users.where(role: courses_user_role).count }
  end

  def status
    return 'Draft' unless published
    return 'Closed' if survey.closed
    return 'Pending' if total_notifications.zero?
    return 'Active' if total_notifications.positive?
  end

  private

  def remove_notifications
    SurveyNotification.where(survey_assignment_id: id).destroy_all
  end
end
