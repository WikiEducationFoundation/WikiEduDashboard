# frozen_string_literal: true

require_dependency Rails.root.join('lib/wiki_course_edits')
require_dependency Rails.root.join('lib/wiki_preferences_manager')

class EnrollInCourseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_edits(course:, editing_user:, enrolling_user:, set_wiki_preferences: false)
    perform_async(course.id, editing_user.id, enrolling_user.id, set_wiki_preferences)
  end

  def perform(course_id, editing_user_id, enrolling_user_id, set_wiki_preferences)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    enrolling_user = User.find(enrolling_user_id)
    WikiCourseEdits.new(action: :enroll_in_course,
                        course:,
                        current_user: editing_user,
                        enrolling_user:)
    WikiCourseEdits.new(action: :update_course,
                        course:,
                        current_user: editing_user)

    return unless set_wiki_preferences
    preferences_manager = WikiPreferencesManager.new(user: enrolling_user)
    preferences_manager.enable_visual_editor
  end
end
