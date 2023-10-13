# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"

class DisenrollFromCourseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_edits(course:, editing_user:, disenrolling_user:)
    perform_async(course.id, editing_user.id, disenrolling_user.id)
  end

  def perform(course_id, editing_user_id, disenrolling_user_id)
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
