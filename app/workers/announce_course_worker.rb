# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_course_edits"

class AnnounceCourseWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_announcement(course:, editing_user:, instructor:)
    perform_async(course.id, editing_user.id, instructor.id)
  end

  def perform(course_id, editing_user_id, instructor_id)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    instructor = User.find(instructor_id)
    WikiCourseEdits.new(action: 'announce_course',
                        course: course,
                        current_user: editing_user,
                        instructor: instructor)
  end
end
