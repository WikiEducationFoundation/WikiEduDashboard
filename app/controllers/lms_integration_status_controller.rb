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

  # The course flag alone isn't enough: it's a denormalized cache, and this
  # endpoint is reachable independently of the gated launch controller, so a
  # disabled integration must stop answering here too.
  def integration_active?
    Features.canvas_integration? && @course.present? && binding.present?
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

  # Links to the Dashboard's own view *inside* the Canvas course rather than the
  # course home page: `external_tools/retrieve` asks Canvas to find the installed
  # tool whose URL matches ours and launch it in the course frame, so the link
  # lands on the same in-iframe view the course-navigation item gives — the
  # instructor status panel, or a student's progress overview.
  #
  # `lms_context_id` is the opaque LTI context id, not Canvas's numeric course
  # id, so it must go through Canvas's `lti_context_id:` API-id lookup prefix —
  # a bare `/courses/<context_id>` 404s ("Couldn't find Course with API id ...").
  # Verified against staging Canvas that `retrieve` accepts the prefixed id too,
  # so no numeric course id is needed.
  #
  # Falls back to the course home page when LTIAAS_DOMAIN isn't configured,
  # since without it there is no launch URL for Canvas to match against.
  def lms_course_url
    return nil if binding.lms_platform_url.blank?

    course_url = "#{binding.lms_platform_url.chomp('/')}" \
                 "/courses/lti_context_id:#{binding.lms_context_id}"
    return course_url if ENV['LTIAAS_DOMAIN'].blank?

    "#{course_url}/external_tools/retrieve?url=#{CGI.escape(tool_launch_url)}"
  end

  # The tool's target_link_uri, as registered with the platform — the same URL
  # BuildLtiDeepLinkForm puts on deep-linked content items.
  def tool_launch_url
    "https://#{ENV.fetch('LTIAAS_DOMAIN', nil)}/lti/launch"
  end

  def staff_metrics
    status = LtiSyncStatus.new(binding)
    {
      last_sync_at: status.last_synced_at,
      last_sync_error_present: status.grade_sync_error?,
      synced_students_count: status.synced_students_count
    }
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
