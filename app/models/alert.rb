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
end

class ArticlesForDeletionAlert < Alert
  def email_content_expert
    content_expert = course.nonstudents.find_by(greeter: true)
    return if content_expert.nil?
    AlertMailer.alert(self, content_expert).deliver_now
    update_attribute(:email_sent_at, Time.now)
  end
end
