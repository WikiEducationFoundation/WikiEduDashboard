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

class Alert < ActiveRecord::Base
  belongs_to :article
  belongs_to :course
  belongs_to :user
  belongs_to :revision

  include ArticleHelper

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
end

# Alert for when an article has been nominated for deletion on English Wikipedia
class ArticlesForDeletionAlert < Alert
  def main_subject
    "#{article.title} — #{course.slug}"
  end

  def url
    article_url(article)
  end
end

# Alert for a course that has no enrolled students after it is underway
class NoEnrolledStudentsAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end

# Alert for a course that has no enrolled students after it is underway
class UntrainedStudentsAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end

# Alert for a course that has no enrolled students after it is underway
class ProductiveCourseAlert < Alert
  def main_subject
    course.slug
  end

  def url
    course_url
  end
end
