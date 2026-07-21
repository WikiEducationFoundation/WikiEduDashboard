# frozen_string_literal: true

# JSON status endpoint for the LMS-integration sidebar component on the
# course page. Returns `{ bound: false }` for any course without an
# active LMS binding so the client can short-circuit cheaply. A bound
# response is scoped to the requesting user's role on the course:
# course instructors get a link-back to the LMS course view + roster
# and grade sync metadata; site admins get the same metadata minus the
# link (they typically don't have access to the LMS instance); students
# get the link plus their own latest grade-push timestamp.
class LmsIntegrationStatusController < ApplicationController
  def show
    @course = Course.find_by(slug: params[:slug])
    return render(json: { bound: false }) unless current_user && integration_active?

    render json: payload_for(role)
  end

  private

  def integration_active?
    @course&.flags&.[](:canvas_integration) && binding.present?
  end

  def binding
    @binding ||= LtiCourseBinding.find_by(course_id: @course.id)
  end

  def role
    return :instructor if current_user.instructor?(@course)
    return :admin if current_user.admin?
    return :student if current_user.student?(@course)
    nil
  end

  def payload_for(role)
    case role
    when :instructor then base.merge(course_url: lms_course_url).merge(staff_metrics)
    when :admin then base.merge(staff_metrics)
    when :student then base.merge(course_url: lms_course_url).merge(student_metrics)
    else { bound: false }
    end
  end

  def base
    {
      bound: true,
      lms_name: binding.lms_display_name,
      course_title: binding.lms_context_title
    }
  end

  def lms_course_url
    return nil if binding.lms_platform_url.blank?
    # `lms_context_id` is the opaque LTI context id, not Canvas's numeric course
    # id, so it must go through Canvas's `lti_context_id:` API-id lookup prefix —
    # a bare `/courses/<context_id>` 404s ("Couldn't find Course with API id ...").
    "#{binding.lms_platform_url.chomp('/')}/courses/lti_context_id:#{binding.lms_context_id}"
  end

  def staff_metrics
    synced = synced_students
    {
      last_sync_at: last_synced_at(synced),
      last_sync_error_present: binding.last_grade_sync_error.present?,
      synced_students_count: synced.size
    }
  end

  # Students only — a bound course's instructor also has a linked context,
  # and counting it would report "1 synced student" before anyone signs in.
  def synced_students
    binding.lti_contexts.linked.reject(&:instructor?)
  end

  # The most recent Canvas sync. Falls through roster sync → grade sync → the
  # latest student link (a student can link via their own launch before either
  # sync runs), so "Last sync" never reads "Not yet synced" while students are
  # already synced.
  def last_synced_at(synced)
    [binding.last_roster_sync_at, binding.last_grade_sync_at,
     synced.filter_map(&:linked_at).max].compact.max
  end

  def student_metrics
    context = binding.lti_contexts.find_by(user_id: current_user.id)
    return { my_linked: false } if context.nil?
    { my_linked: true, my_last_sync_at: latest_push_for(context) }
  end

  def latest_push_for(context)
    LtiScoreSignature.where(lti_context_id: context.id).maximum(:last_pushed_at)
  end
end
