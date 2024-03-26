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

class Alert < ApplicationRecord
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
    BadWorkAlert
    BlockedEditsAlert
    BlockedUserAlert
    ContinuedCourseActivityAlert
    CheckTimelineAlert
    DeletedUploadsAlert
    DeUserfyingAlert
    DiscretionarySanctionsAssignmentAlert
    DiscretionarySanctionsEditAlert
    DYKNominationAlert
    FirstEnrolledStudentAlert
    GANominationAlert
    HighQualityArticleAssignmentAlert
    HighQualityArticleEditAlert
    NeedHelpAlert
    NoTaEnrolledAlert
    NoEnrolledStudentsAlert
    NoMedTrainingForCourseAlert
    OnboardingAlert
    OverdueTrainingAlert
    OverEnrollmentAlert
    ProductiveCourseAlert
    ProtectedArticleAssignmentAlert
    ReviewRequestAlert
    SandboxedCourseMainspaceAlert
    SurveyResponseAlert
    UnsubmittedCourseAlert
    UntrainedStudentsAlert
    InstructorNotificationAlert
  ].freeze
  validates_inclusion_of :type, in: ALERT_TYPES

  RESOLVABLE_ALERT_TYPES = %w[
    ArticlesForDeletionAlert
    BadWorkAlert
    CheckTimelineAlert
    ContinuedCourseActivityAlert
    DiscretionarySanctionsAssignmentAlert
    DiscretionarySanctionsEditAlert
    DYKNominationAlert
    GANominationAlert
    HighQualityArticleAssignmentAlert
    HighQualityArticleEditAlert
    OverEnrollmentAlert
  ].freeze

  PUBLIC_ALERT_TYPES = %w[
    ActiveCourseAlert
    ArticlesForDeletionAlert
    BlockedEditsAlert
    BlockedUserAlert
    ContinuedCourseActivityAlert
    DeletedUploadsAlert
    DiscretionarySanctionsAssignmentAlert
    DiscretionarySanctionsEditAlert
    DYKNominationAlert
    GANominationAlert
    HighQualityArticleAssignmentAlert
    HighQualityArticleEditAlert
    NoEnrolledStudentsAlert
    ProductiveCourseAlert
    ProtectedArticleAssignmentAlert
    UnsubmittedCourseAlert
    UntrainedStudentsAlert
    SandboxedCourseMainspaceAlert
  ].freeze

  scope :nonprivate, -> { where(type: PUBLIC_ALERT_TYPES) }

  def course_url
    "https://#{ENV['dashboard_url']}/courses/#{course.slug}"
  end

  def user_profile_url
    "https://#{ENV['dashboard_url']}/users/#{user.username}"
  end

  def user_contributions_url
    courses_user&.contribution_url
  end

  def content_experts
    course.nonstudents.where(greeter: true)
  end

  def email_content_expert
    return if emails_disabled?
    return if course.nil?
    experts = content_experts
    return if experts.empty?
    experts.each { |expert| AlertMailer.send_alert_email(self, expert) }
    update(email_sent_at: Time.zone.now)
  end

  def email_course_admins
    return if emails_disabled?
    admins = course.nonstudents.where(permissions: 1)
    admins.each do |admin|
      AlertMailer.send_alert_email(self, admin)
    end
    update(email_sent_at: Time.zone.now)
  end

  def email_target_user
    return if emails_disabled?
    return if target_user.nil?
    AlertMailer.send_alert_email(self, target_user)
    update(email_sent_at: Time.zone.now)
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

  def ticket_body
    raise NotImplementedError
  end

  def reply_to
    SpecialUsers.technical_help_staff&.email
  end

  def resolvable?
    false
  end

  def opt_out_link
    nil
  end

  def resolve_explanation
    <<~EXPLANATION
      Resolving the alert should be done if the situation that caused it is no
      longer going on. The Dashboard will create a new alert if it detects the
      same situation again.
    EXPLANATION
  end

  def courses_user
    return unless course && user
    @courses_user ||= CoursesUsers.find_by(course_id: course.id, user_id: user.id)
  end
end
