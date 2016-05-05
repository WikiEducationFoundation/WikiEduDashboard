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
    pp 'An article might get deleted!'
    pp self
  end
end
