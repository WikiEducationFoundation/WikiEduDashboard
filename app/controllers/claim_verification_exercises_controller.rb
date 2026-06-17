# frozen_string_literal: true

# Shows a signed-in student the claim-verification exercise for a course: the
# single pooled claim they have been assigned, its cited source (link out), and
# a handoff to do the verification in their Wikipedia sandbox. The student
# records their findings on-wiki; nothing they produce is stored here.
#
# Reached two ways: the course-scoped route (courses/*id/verify_claim, linked
# relatively from the timeline) carries the slug directly; the slug-less route
# (verify_claim, linked from the course-agnostic exercise training module)
# infers the course from the training return-to or the user's sole course, and
# falls back to a course picker when it can't tell.
class ClaimVerificationExercisesController < ApplicationController
  before_action :require_signed_in

  def show
    @course = course_from_slug || inferred_course
    return render(:course_picker) if @course.nil?

    @assignment = AssignVerificationClaim.new(user: current_user, course: @course).assignment
    @claim = @assignment&.verification_claim
  end

  private

  def course_from_slug
    return if params[:id].blank?
    course = Course.find_by(slug: params[:id])
    raise ActionController::RoutingError, 'Course not found' if course.nil?
    course
  end

  def inferred_course
    @courses = current_user.courses
    course_from_return_to || (@courses.first if @courses.one?)
  end

  def course_from_return_to
    path = params[:return_to].presence || session[:training_return_to]
    return if path.blank?
    slug = slug_from_course_path(path)
    slug.present? && Course.find_by(slug:)
  rescue URI::InvalidURIError
    nil
  end

  # "/courses/School/Title_(Term)/timeline" -> "School/Title_(Term)".
  # Course slugs are exactly school/title (one slash), so take the two
  # segments after "courses".
  def slug_from_course_path(path)
    segments = URI(path).path.split('/').compact_blank
    index = segments.index('courses')
    return if index.nil?
    CGI.unescape(segments[index + 1, 2].to_a.join('/'))
  end
end
