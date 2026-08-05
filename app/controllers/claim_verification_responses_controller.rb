# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"

# Student responses for the claim-verification exercise, which is done
# entirely in the dashboard: the student answers the form on their taken
# claim (`create`, an upsert — they may revise their answers), and `index`
# serves the submissions back — everyone's for the course's instructional
# staff, their own for an enrolled student.
class ClaimVerificationResponsesController < ApplicationController
  respond_to :json
  before_action :require_signed_in
  before_action :set_course

  # Upsert the current user's response. Requires a taken claim — the form only
  # exists on the taken-claim view — and course enrollment. Submission marks
  # the exercise's training module complete for this course.
  def create
    return head(:forbidden) unless enrolled_in_course?
    assignment = VerificationClaimAssignment.find_by(user: current_user, course: @course)
    return head(:unprocessable_entity) if assignment.nil?
    @response = RecordVerificationClaimResponse.new(assignment:, answers: answer_params).response
    return render_validation_errors unless @response.errors.empty?
    # renders create.json.jbuilder
  end

  # Submitted responses plus taken-but-unsubmitted claims, scoped to the
  # viewer: the course's instructional staff read everyone's, while an
  # enrolled student reads only their own.
  def index
    scope = viewer_scope
    return head(:forbidden) if scope.nil?
    @responses = VerificationClaimResponse.where(course: @course, **scope)
                                          .includes(:user, verification_claim: :wiki)
                                          .order(:created_at)
    @pending = pending_assignments(scope)
    # The questions each response answered, so the view can show them as asked.
    @form = ClaimVerification::ExerciseForm.new
    # renders index.json.jbuilder
  end

  private

  # Whatever the exercise currently asks — the question ids come from
  # config/claim_verification_exercise.yml, so a new question needs no change
  # here. Answers to questions the student's path skipped are dropped downstream.
  def answer_params
    params.permit(*ClaimVerification::ExerciseForm.new.answer_keys)
  end

  def render_validation_errors
    render json: { errors: @response.errors.full_messages }, status: :unprocessable_entity
  end

  # Who may read what: staff read everyone's responses ({}), an enrolled
  # student reads only their own, and anyone else is refused (nil).
  def viewer_scope
    return {} if can_view_responses?
    return { user: current_user } if enrolled_in_course?
    nil
  end

  # Current claims with no submitted form yet. Responses are keyed per claim,
  # so a student who submitted for an earlier claim and then took a new one
  # counts as pending again for the new claim.
  def pending_assignments(scope)
    responded = @responses.map { |r| [r.user_id, r.verification_claim_id] }.to_set
    VerificationClaimAssignment.where(course: @course, **scope)
                               .includes(:user, verification_claim: :wiki)
                               .reject do |assignment|
      responded.include?([assignment.user_id, assignment.verification_claim_id])
    end
  end

  def enrolled_in_course?
    current_user.courses.exists?(@course.id)
  end

  # Any non-student course role (or admin) may read the responses; students
  # may not see each other's answers.
  NONSTUDENT_ROLES = [
    CoursesUsers::Roles::INSTRUCTOR_ROLE,
    CoursesUsers::Roles::CAMPUS_VOLUNTEER_ROLE,
    CoursesUsers::Roles::ONLINE_VOLUNTEER_ROLE,
    CoursesUsers::Roles::WIKI_ED_STAFF_ROLE
  ].freeze

  def can_view_responses?
    current_user.admin? ||
      current_user.courses_users.exists?(course: @course, role: NONSTUDENT_ROLES)
  end

  def set_course
    @course = Course.find_by(slug: params[:id])
    raise ActionController::RoutingError, 'Course not found' if @course.nil?
  end
end
