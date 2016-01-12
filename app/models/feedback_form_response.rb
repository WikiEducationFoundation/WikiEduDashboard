class FeedbackFormResponse < ActiveRecord::Base
  def module
    path = URI.parse(subject).path
    parts = path.split('/')
    parts[3]
  end
end
