# frozen_string_literal: true

# Data + entry for the student claim-verification exercise (issue #6910).
# The exercise UI itself is the course SPA: `/courses/*id/verify_claim` falls
# through to `courses#show` and React Router renders the exercise (article
# picker → in-viewer claim selection → taken claim) with no reloads. This
# controller serves only that flow's JSON and the slug-less entry funnel:
# - GET state: the student's taken claim + submitted response (if any) + the
#   (article, flagged revision) tiles they can pick, drawn from the
#   pre-harvested claim pool.
# - GET annotated_article: the flagged revision's HTML with its pre-harvested
#   claims tagged.
# - POST take: assign the chosen (already-persisted) pool claim, return it.
# - GET entry (slug-less): infer the course and send the student into its SPA
#   exercise, else show a course picker.
# Claims are harvested ahead of time (rake claim_verification:harvest_pool) from
# mainspace AiEditAlert revisions; the student then does the verification in
# the dashboard, submitting the form handled by
# ClaimVerificationResponsesController.
class ClaimVerificationExercisesController < ApplicationController
  before_action :require_signed_in

  def state
    @course = course_from_slug
    @assignment = VerificationClaimAssignment.find_by(user: current_user, course: @course)
    # The response for the *current* claim (responses are keyed per claim);
    # after switching claims, the fresh claim has no response yet.
    @response = @assignment && VerificationClaimResponse.find_by(
      user: current_user, course: @course,
      verification_claim: @assignment.verification_claim
    )
    @tiles = RelevantClaimRevisionsForCourse.new(@course).tiles
    # renders state.json.jbuilder
  end

  # JSON: the flagged revision's parsed HTML with its pre-harvested claims tagged,
  # for the in-viewer claim picker. The claim-highlighting hook fetches this once
  # the ArticleViewer shell has resolved the title at the flagged revision.
  def annotated_article
    article = Article.find(params[:article_id])
    annotation = AnnotateRevisionClaims.new(article:, mw_rev_id: params[:mw_rev_id].to_i)
    render json: { html: annotation.html, mw_rev_id: annotation.mw_rev_id }
  end

  # Assigning a claim is the only write in this controller, so it's the only
  # action that requires course enrollment: any signed-in user may browse a
  # course's claims (state / annotated_article), but only a user enrolled in the
  # course may create an assignment record in it.
  def take
    @course = course_from_slug
    return head(:forbidden) unless enrolled_in_course?
    claim = VerificationClaim.find_by(id: params[:verification_claim_id])
    assign(claim) if claim
    # An earlier response for this same claim, if any (responses are keyed per
    # claim, so switching claims never orphans one) — re-taking a claim brings
    # the student back to their submitted answers.
    @response = claim && VerificationClaimResponse.find_by(user: current_user, course: @course,
                                                           verification_claim: claim)
    # renders take.json.jbuilder (@assignment is nil if the claim was not found),
    # so the SPA can transition. Claims are shareable: no exclusivity is enforced.
  end

  # Slug-less entry: send the student into the inferred course's SPA exercise,
  # or ask which course when we can't tell.
  def entry
    course = inferred_course
    return render(:course_picker) if course.nil?
    redirect_to "/courses/#{course.slug}/verify_claim"
  end

  private

  # Enrolled in @course via any courses_users role (student, instructor, …).
  def enrolled_in_course?
    current_user.courses.exists?(@course&.id)
  end

  # One active pick per student per course (the assignment's uniqueness), but the
  # same pool claim may be assigned to any number of students.
  def assign(claim)
    @assignment = VerificationClaimAssignment.find_or_initialize_by(user: current_user,
                                                                    course: @course)
    @assignment.update!(verification_claim: claim)
  end

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
