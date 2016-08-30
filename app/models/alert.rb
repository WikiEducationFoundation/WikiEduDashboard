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
#

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
    DeletedUploadsAlert
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
