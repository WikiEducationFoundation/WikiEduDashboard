# frozen_string_literal: true

# The unlisted page where an instructor issues LTI 1.1 credentials for their
# own course, at `/courses/<slug>/canvas`.
#
# Nothing in the interface links here. Wiki Education sends the URL to the beta
# instructors whose Canvas cannot install the LTI 1.3 tool, which keeps the 1.1
# path from competing with 1.3 for everyone else's attention. That obscurity
# governs discovery only: every request is still checked for a signed-in
# instructor of an approved course, with the legacy-launch flags on.
class CourseCanvasCredentialsController < ApplicationController
  before_action :require_legacy_lti_enabled
  before_action :set_course
  before_action :require_course_instructor

  def show
    prepare_view
  end

  # Issues a key, or replaces the course's existing one. The secret is put in
  # `@secret` for this render alone: ActiveRecord encryption would happily
  # decrypt it again on a later request, so showing it once is a deliberate
  # policy rather than a technical limit — a long-lived secret sitting on a
  # page someone left open is exactly what we don't want.
  def create
    prepare_view
    return render :show if @bound_elsewhere

    key = LtiConsumerKey.generate_for(course: @course, user: current_user)
    @key = key
    @secret = key.secret
    render :show
  end

  private

  def prepare_view
    @key = LtiConsumerKey.active.find_by(course: @course)
    # A 1.3 binding is the standard install, and it wins whatever key this page
    # has issued: a course with a live 1.1 key that later gets a 1.3 install
    # must not show the waiting state and offer to regenerate. Read from the
    # binding table rather than the course's denormalized flag, which is a
    # cache the model keeps best-effort. A legacy binding is this page's own
    # doing and does not count.
    @bound_elsewhere = LtiCourseBinding.lti_1_3.exists?(course_id: @course.id)
    @config_url = "https://#{ENV.fetch('dashboard_url')}/lti/legacy/config.xml"
  end

  def require_legacy_lti_enabled
    return if Features.canvas_integration? && Features.lti_legacy_launches?

    # 404 rather than a refusal: where the feature is off, the page does not
    # exist. Same reasoning as LtiLaunchController's gate.
    head :not_found
  end

  def set_course
    @course = Course.find_by(slug: params[:slug])
    raise ActionController::RoutingError, 'Not Found' if @course.nil?
  end

  # Instructors of the course only, and only once the course is approved —
  # an unapproved course cannot enroll anyone, so connecting it to Canvas
  # would produce a link that does nothing.
  def require_course_instructor
    raise NotPermittedError unless current_user&.instructor?(@course) && @course.approved?
  end
end
