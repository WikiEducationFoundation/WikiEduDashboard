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

  def handle_student_launch
    return render 'lti_launch/setup_pending' if @binding.course.nil?
    return redirect_to "/courses/#{@binding.course.slug}" if enrolled?

    result = join_course_for_student
    return redirect_to "/courses/#{@binding.course.slug}" if join_succeeded?(result)
    return render 'lti_launch/enrollment_pending_approval' if pending_approval?(result)

    report_join_failure(result)
    render 'lti_launch/enrollment_error'
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

  def enrolled?
    CoursesUsers.exists?(user_id: current_user.id, course_id: @binding.course_id)
  end
end
