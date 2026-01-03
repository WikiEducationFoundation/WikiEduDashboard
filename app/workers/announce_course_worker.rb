# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"

class AnnounceCourseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_announcement(course:, editing_user:, instructor:,
                                 action: 'add_course_template_to_instructor_userpage')
    perform_async(course.id, editing_user.id, instructor.id, action)
  end

  def perform(course_id, editing_user_id, instructor_id,
              action = 'add_course_template_to_instructor_userpage')
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    instructor = User.find(instructor_id)
    WikiCourseEdits.new(action:,
                        course:,
                        current_user: editing_user,
                        instructor:)
  end
end
