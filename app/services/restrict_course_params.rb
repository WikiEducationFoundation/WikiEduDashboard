# frozen_string_literal: true

# Removes the course settings a user may not change from the course params of
# CoursesController#create and #update, following what the course creator and
# the course page's Details panel offer each user. Clients send the whole
# course back on every update, so disallowed settings are dropped, not refused.
class RestrictCourseParams
  # Only admins see these in the Details panel. `flags` carries max_group_size.
  ADMIN_ONLY = %w[withdrawn declined stay_in_sandbox no_sandboxes
                  retain_available_articles last_reviewed flags].freeze
  # The course creator and the clone setup modal set the subject, so it is
  # only restricted on a course that is already set up.
  ADMIN_ONLY_AFTER_SETUP = %w[subject].freeze
  SETUP_CLONED_STATUSES = [Course::ClonedStatus::PENDING, Course::ClonedStatus::COPIED].freeze
  # Offered to users who may rename the course: admins, and any course editor on P&E.
  RENAMER_ONLY = (%w[type private timeline_enabled wiki_edits_enabled
                     online_volunteers_enabled disable_student_emails] +
                  Course::EDIT_SETTING_KEYS).freeze
  # The types the course creator and the type selector offer outside Wiki Ed.
  RENAMER_TYPES = %w[BasicCourse Editathon ArticleScopedProgram SingleUser].freeze

  # course is nil when creating.
  def initialize(course_params:, user:, course:)
    @course_params = course_params
    @course = course
    restrict unless user.admin?
  end

  private

  def restrict
    drop ADMIN_ONLY
    drop ADMIN_ONLY_AFTER_SETUP unless in_setup?
    drop RENAMER_ONLY - %w[type] if Features.wiki_ed?
    drop %w[type] unless permitted_type?
    # Instructors may submit a course and finish setting up a clone, but not undo either.
    drop %w[submitted] unless @course_params[:submitted] == true
    drop %w[cloned_status] unless @course_params[:cloned_status] == Course::ClonedStatus::COMPLETED
  end

  def in_setup?
    @course.nil? || SETUP_CLONED_STATUSES.include?(@course.cloned_status)
  end

  def permitted_type?
    return true if campaign_default_type?
    !Features.wiki_ed? && RENAMER_TYPES.include?(@course_params[:type])
  end

  # The course creator takes the type from the campaign it was opened from.
  def campaign_default_type?
    return false unless @course.nil? && @course_params[:type].present?
    campaign = Campaign.find_by(id: @course_params[:initial_campaign_id])
    campaign&.default_course_type == @course_params[:type]
  end

  def drop(keys)
    keys.each { |key| @course_params.delete(key) }
  end
end
