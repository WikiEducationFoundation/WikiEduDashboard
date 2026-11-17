# frozen_string_literal: true

# The application form for a Scholars & Scientists course (Wiki Education
# Dashboard only). The apply link, /courses/<slug>/apply, is the course page
# with an application card at the top (ApplyCard, fed by the course JSON's
# `application` block): it explains logging in, says when the form is closed
# or already submitted, and otherwise links here, to /courses/<slug>/apply/form.
# This page is only the form; anyone who can't use it right now goes back to
# the card, and a successful submission does too.
class CourseApplicationsController < ApplicationController
  before_action :require_wiki_ed
  before_action :set_course_and_form
  before_action :send_enrolled_students_to_course

  def show
    return redirect_to apply_path unless current_user && may_apply?

    @answers_by_question_id = {}
  end

  def create
    require_signed_in
    return redirect_to apply_path, status: :see_other unless may_apply?

    submission = SubmitCourseApplication.new(course: @course, user: current_user,
                                             answers: submitted_answers)
    return redirect_to apply_path, status: :see_other if submission.success?

    @answers_by_question_id = submission.answers_by_question_id
    @invalid = true
    render :show, status: :unprocessable_content
  end

  private

  def require_wiki_ed
    raise ActionController::RoutingError, 'Not Found' unless Features.wiki_ed?
  end

  def set_course_and_form
    @course = Course.find_by(slug: params[:slug])
    raise ActionController::RoutingError, 'Not Found' unless @course&.applications_allowed?

    @form = @course.course_application_form
    @application = current_user && @course.course_applications.find_by(user: current_user)
  end

  # Applying is pointless for someone already in the course.
  def send_enrolled_students_to_course
    return unless current_user
    return unless CoursesUsers.exists?(course: @course, user: current_user,
                                       role: CoursesUsers::Roles::STUDENT_ROLE)
    redirect_to course_slug_path(@course.slug)
  end

  def may_apply?
    @application.nil? && @form&.accepting_applications?
  end

  # Only the answers are read, and only by question id, so the hash is taken
  # as submitted.
  def submitted_answers
    params[:answers]&.to_unsafe_h || {}
  end

  def apply_path
    "/courses/#{@course.slug}/apply"
  end
end
