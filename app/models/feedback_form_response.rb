# frozen_string_literal: true

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

class FeedbackFormResponse < ApplicationRecord
  def topic
    if %r{/training/}.match? subject
      path = URI.parse(subject).path
      parts = path.split('/')
      return parts[3]
    end
    subject
  end
end
