# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_course_edits"

class UpdateCourseWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_edits(course:, editing_user:)
    perform_async(course.id, editing_user.id)
  end

  def perform(course_id, editing_user_id)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    WikiCourseEdits.new(action: :update_course, course: course, current_user: editing_user)
  end
end
