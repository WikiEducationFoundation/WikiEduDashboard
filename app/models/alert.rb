# == Schema Information
#
# Table name: alerts
#
# id
# type
# created_at
# updated_at
# article_id
# user_id
# revision_id
# course_id
# email_sent_at
# target_user_id
# message

class Alert < ActiveRecord::Base
  belongs_to :article
  belongs_to :course
  belongs_to :user
  belongs_to :target_user, class_name: 'User'
  belongs_to :revision

  include ArticleHelper

  ALERT_TYPES = %w(
    ActiveCourseAlert
    ArticlesForDeletionAlert
    ContinuedCourseActivityAlert
    NeedHelpAlert
    NoEnrolledStudentsAlert
    ProductiveCourseAlert
    UntrainedStudentsAlert
  ).freeze
  validates_inclusion_of :type, in: ALERT_TYPES

  def course_url
    "https://#{ENV['dashboard_url']}/courses/#{course.slug}"
  end

  def email_content_expert
    content_expert = course.nonstudents.find_by(greeter: true)
    return if content_expert.nil?
    AlertMailer.alert(self, content_expert).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end

  def email_course_admins
    admins = course.nonstudents.where(permissions: 1)
    admins.each do |admin|
      AlertMailer.alert(self, admin).deliver_now
    end
    update_attribute(:email_sent_at, Time.now)
  end

  def email_target_user
    return if target_user.nil?
    AlertMailer.alert(self, target_user).deliver_now
    update_attribute(:email_sent_at, Time.now)
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
end
