# frozen_string_literal: true

# Removes the course settings a user may not change from the course params of
# CoursesController#create and #update, following what the course creator and
# the course page's Details panel offer each user. Clients send the whole
# course back on every update, so disallowed settings are dropped, not refused.
class RestrictCourseParams
  # Only admins see these in the Details panel. `flags` carries max_group_size.
  ADMIN_ONLY = %w[withdrawn declined stay_in_sandbox no_sandboxes
                  retain_available_articles last_reviewed flags].freeze
  # The course creator sets the subject, so it is only restricted on update.
  ADMIN_ONLY_ON_UPDATE = %w[subject].freeze
  # Offered to users who may rename the course: admins, and any course editor on P&E.
  RENAMER_ONLY = (%w[type private timeline_enabled wiki_edits_enabled
                     online_volunteers_enabled disable_student_emails] +
                  Course::EDIT_SETTING_KEYS).freeze
  # The types the course creator and the type selector offer outside Wiki Ed.
  RENAMER_TYPES = %w[BasicCourse Editathon ArticleScopedProgram SingleUser].freeze

  def initialize(course_params:, user:, creating:)
    @course_params = course_params
    @creating = creating
    restrict unless user.admin?
  end

  private

  def restrict
    drop ADMIN_ONLY
    drop ADMIN_ONLY_ON_UPDATE unless @creating
    drop RENAMER_ONLY if Features.wiki_ed?
    drop %w[type] unless RENAMER_TYPES.include?(@course_params[:type])
    # Instructors may submit a course and finish setting up a clone, but not undo either.
    drop %w[submitted] unless @course_params[:submitted] == true
    drop %w[cloned_status] unless @course_params[:cloned_status] == Course::ClonedStatus::COMPLETED
  end

  def drop(keys)
    keys.each { |key| @course_params.delete(key) }
  end
end
