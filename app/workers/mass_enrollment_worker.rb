# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_course_edits"

class MassEnrollmentWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed,
                  retry: 0 # Move job to the 'dead' queue if it fails

  def self.schedule_edits(course:, editing_user:, enrollment_results:)
    perform_async(course.id, editing_user.id, enrollment_results)
  end

  def perform(course_id, editing_user_id, enrollment_results)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    WikiCourseEdits.new(action: :update_course, course: course, current_user: editing_user)

    enrollment_results.each do |username, result|
      next unless result.key?('success')
      enrolling_user = User.find_by(username: username)
      WikiCourseEdits.new(action: :enroll_in_course,
                          course: course,
                          current_user: editing_user,
                          enrolling_user: enrolling_user)
    end
  end
end
