# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_edits"

class NotifyUntrainedUsersWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_notifications(course:, notifying_user:)
    perform_async(course.id, notifying_user.id)
  end

  def perform(course_id, notifying_user_id)
    course = Course.find(course_id)
    notifying_user = User.find(notifying_user_id)
    WikiEdits.new(course.home_wiki).notify_untrained(course, notifying_user)
  end
end
