# == Schema Information
#
# Table name: feedback_form_responses
#
#  id         :integer          not null, primary key
#  subject    :string(255)
#  body       :text(65535)
#  user_id    :integer
#  created_at :datetime
#

class FeedbackFormResponse < ActiveRecord::Base
  def module
    path = URI.parse(subject).path
    parts = path.split('/')
    parts[3]
  end
end
