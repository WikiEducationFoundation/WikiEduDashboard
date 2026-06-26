# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"
require_dependency "#{Rails.root}/lib/timeslice_cleaner"

class DeleteCourseWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def self.schedule_deletion(course:, current_user:)
    perform_async(course.id, current_user.id)
  end

  def perform(course_id, current_user_id)
    course = Course.find(course_id)
    current_user = User.find(current_user_id)

    # Logging to know who performed the deletion
    Sentry.capture_message 'course deletion',
                           level: 'info',
                           extra: {
                             course_slug: course.slug,
                             course: course.as_json,
                             participants: course_users(course),
                             username: current_user.username
                           }
    # Delete timeslices in batches first. They are not dependent: :destroy on
    # Course (see the Course model), because the destroy cascade is far too slow
    # for the millions of timeslice rows large courses can have. This must run
    # before course.destroy, which no longer removes them.
    TimesliceCleaner.new(course).delete_all_timeslices_for_course
    # destroy the course, clean up the on-wiki copy if necessary
    course.destroy
    WikiCourseEdits.new(action: :update_course,
                        course:,
                        current_user:,
                        delete: true)
  end

  def course_users(course)
    course.courses_users.includes(:user).map do |courses_user|
      [courses_user.user.username, courses_user.role]
    end
  end
end
