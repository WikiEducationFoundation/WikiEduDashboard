# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_course_edits"

class RemoveAssignmentWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def self.schedule_edits(course:, editing_user:, assignment:)
    perform_async(course.id, editing_user.id, assignment.id)
  end

  def perform(course_id, editing_user_id, assignment_id)
    course = Course.find(course_id)
    editing_user = User.find(editing_user_id)
    assignment = Assignment.find(assignment_id)
    WikiCourseEdits.new(action: :remove_assignment, course: course,
                        current_user: editing_user, assignment: assignment)
  end
end
