# frozen_string_literal: true
# == Schema Information
#
# Table name: alerts
#
#  id             :integer          not null, primary key
#  course_id      :integer
#  user_id        :integer
#  article_id     :integer
#  revision_id    :integer
#  type           :string(255)
#  email_sent_at  :datetime
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  message        :text(65535)
#  target_user_id :integer
#  subject_id     :integer
#  resolved       :boolean          default(FALSE)
#  details        :text(65535)
#

class Alert < ActiveRecord::Base
  belongs_to :article
  belongs_to :course
  belongs_to :user
  belongs_to :target_user, class_name: 'User'
  belongs_to :revision

  include ArticleHelper

  serialize :details, Hash

  ALERT_TYPES = %w[
    ActiveCourseAlert
    ArticlesForDeletionAlert
    BlockedEditsAlert
    ContinuedCourseActivityAlert
    DeletedUploadsAlert
    DiscretionarySanctionsEditAlert
    DYKNominationAlert
    NeedHelpAlert
    NoEnrolledStudentsAlert
    ProductiveCourseAlert
    SurveyResponseAlert
    UnsubmittedCourseAlert
    UntrainedStudentsAlert
  ].freeze
  validates_inclusion_of :type, in: ALERT_TYPES

  RESOLVABLE_ALERT_TYPES = %w[
    ArticlesForDeletionAlert
    ContinuedCourseActivityAlert
    DiscretionarySanctionsEditAlert
    DYKNominationAlert
  ].freeze

  def course_url
    "https://#{ENV['dashboard_url']}/courses/#{course.slug}"
  end

  def user_profile_url
    "https://#{ENV['dashboard_url']}/users/#{user.username}"
  end

  def user_contributions_url
    courses_user&.contribution_url
  end

  def email_content_expert
    return if emails_disabled?
    content_expert = course.nonstudents.find_by(greeter: true)
    return if content_expert.nil?
    AlertMailer.alert(self, content_expert).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end

  def email_course_admins
    return if emails_disabled?
    admins = course.nonstudents.where(permissions: 1)
    admins.each do |admin|
      AlertMailer.alert(self, admin).deliver_now
    end
    update_attribute(:email_sent_at, Time.now)
  end

  def email_target_user
    return if emails_disabled?
    return if target_user.nil?
    AlertMailer.alert(self, target_user).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end

  # Disable emails for specific alert types in application.yml, like so:
  #   ProductiveCourseAlert_email_disabled: 'true'
  def emails_disabled?
    ENV["#{self.class}_emails_disabled"] == 'true'
  end

  # This can be used to copy dashboard emails to Salesforce
  def bcc_to_salesforce_email
    ENV['bcc_to_salesforce_email']
  end

  #########################
  # Type-specific methods #
  #########################

  def main_subject
    raise NotImplementedError
  end

  def url
    raise NotImplementedError
  end

  def reply_to
    nil
  end

  def resolvable?
    false
  end

  def courses_user
    return unless course && user
    @courses_user ||= CoursesUsers.find_by(course_id: course.id, user_id: user.id)
  end
end
