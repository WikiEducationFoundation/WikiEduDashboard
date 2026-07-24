# frozen_string_literal: true

# Student-launch handling for the LTI flow, mixed into LtiLaunchController:
# enroll the launching student in the bound Dashboard course (or explain why
# not yet — course unbound, awaiting approval, or a hard failure).
#
# Lives in a concern so the shared launch plumbing (build_lti_session,
# allow_iframe, the canvas-integration flag gate) stays in one place while
# keeping LtiLaunchController within its length budget.
module LtiStudentEnrollment
  extend ActiveSupport::Concern

  private

  # Enrollment for launches that aren't the course-navigation one — i.e. a
  # student opening a Dashboard assignment. That is the *only* launch a
  # student ever makes in a course whose navigation tab is off, so it has to
  # carry the enrollment the nav launch used to: without it the student is
  # never joined to the Dashboard course and their LtiContext never links, so
  # grade sync skips them and the setup roster counts them pending forever.
  #
  # Returns false only when the course isn't approved yet — the one failure
  # the student can act on, and where an assignment drill-down would just
  # look empty. Any other failure is reported and the drill-down still
  # renders; a read-only view is better than a dead end.
  def ensure_launch_enrollment
    return true unless enrollable_student?

    result = join_course_for_student
    return true if join_succeeded?(result)
    return false if pending_approval?(result)

    report_join_failure(result)
    true
  end

  def enrollable_student?
    current_user && @lti_session.student? && @binding&.course && !enrolled?
  end

  def handle_student_launch
    return render 'lti_launch/setup_pending' if @binding.course.nil?
    return student_destination if enrolled?

    result = join_course_for_student
    return student_destination if join_succeeded?(result)
    return render 'lti_launch/enrollment_pending_approval' if pending_approval?(result)

    report_join_failure(result)
    render 'lti_launch/enrollment_error'
  end

  # Where an enrolled student's launch lands. Top level (the new tab after
  # OAuth): the course page itself. Inside the Canvas iframe: an in-iframe
  # status view — the course page can't be framed (its X-Frame-Options
  # blocks the iframe outright in Firefox, which regains the session inside
  # the iframe via storage-access heuristics after the top-level login).
  def student_destination
    return redirect_to "/courses/#{@binding.course.slug}" unless framed_request?

    render_student_status(user: current_user)
  end

  def join_course_for_student
    JoinCourse.new(course: @binding.course, user: current_user,
                   role: CoursesUsers::Roles::STUDENT_ROLE,
                   real_name: current_user.real_name).result
  end

  def join_succeeded?(result)
    result['success'] || result['failure'] == 'cannot_join_twice'
  end

  def pending_approval?(result)
    result['failure'] == 'not_yet_approved'
  end

  def report_join_failure(result)
    Sentry.capture_message(
      'LTI student launch JoinCourse failure',
      extra: { binding_id: @binding.id, user_id: current_user.id,
               failure: result['failure'] }
    )
  end

  def enrolled?(user = current_user)
    user && CoursesUsers.exists?(user_id: user.id, course_id: @binding.course_id)
  end
end
