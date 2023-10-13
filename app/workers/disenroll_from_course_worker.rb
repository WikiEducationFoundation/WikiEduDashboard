# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"
require_dependency "#{Rails.root}/lib/wiki_preferences_manager"

class DisenrollFromCourseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_edits(course:, editing_user:, disenrolling_user:, set_wiki_preferences: false)
    perform_async(course.id, editing_user.id, disenrolling_user.id, set_wiki_preferences)
  end

  def perform(course_id, editing_user_id, disenrolling_user_id, _set_wiki_preferences)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    disenrolling_user = User.find(disenrolling_user_id)
    WikiCourseEdits.new(action: :disenroll_from_course,
                        course:,
                        current_user: editing_user,
                        disenrolling_user:)
    WikiCourseEdits.new(action: :update_course,
                        course:,
                        current_user: editing_user)
  end
end
