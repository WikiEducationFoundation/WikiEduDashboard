# frozen_string_literal: true

# The public apply page for a Scholars & Scientists course, at
# /courses/<slug>/apply. Anyone can see it; applying takes a Wikipedia login.
# Depending on who is looking, it shows the login prompt, the form, a closed
# notice, or — once someone has applied — a confirmation (and nothing more:
# decisions are not shown here). Wiki Education Dashboard only.
class CourseApplicationsController < ApplicationController
  before_action :require_wiki_ed
  before_action :set_course_and_form
  before_action :send_enrolled_students_to_course

  def show
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
