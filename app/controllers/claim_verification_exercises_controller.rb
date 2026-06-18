# frozen_string_literal: true

# Data + entry for the student claim-verification exercise (issue #6910).
# The exercise UI itself is the course SPA: `/courses/*id/verify_claim` falls
# through to `courses#show` and React Router renders the exercise (article
# picker → in-viewer claim selection → taken claim) with no reloads. This
# controller serves only that flow's JSON and the slug-less entry funnel:
# - GET state: the student's taken claim (if any) + the articles they can pick.
# - GET annotated_article: an article's parsed HTML with cited claims tagged.
# - POST take: persist the chosen claim, record the assignment, return it.
# - GET entry (slug-less): infer the course and send the student into its SPA
#   exercise, else show a course picker.
# Articles are harvested on demand; only the taken claim is persisted. The
# student does the verification in their sandbox; nothing they produce is stored.
class ClaimVerificationExercisesController < ApplicationController
  before_action :require_signed_in

  def state
    @course = course_from_slug
    @assignment = VerificationClaimAssignment.find_by(user: current_user, course: @course)
    @articles = RelevantArticlesForCourse.new(@course).articles
    # renders state.json.jbuilder
  end

  # JSON: the article's parsed HTML with its cited claims tagged, for the
  # in-viewer claim picker. The claim-highlighting hook fetches this once the
  # ArticleViewer shell has resolved the title.
  def annotated_article
    annotation = AnnotateArticleClaims.new(Article.find(params[:article_id]))
    render json: { html: annotation.html, mw_rev_id: annotation.mw_rev_id }
  end

  def take
    @course = course_from_slug
    TakeVerificationClaim.new(user: current_user, course: @course,
                              article: Article.find(params[:article_id]),
                              sentence: params[:sentence], ref_id: params[:ref_id])
    @assignment = VerificationClaimAssignment.find_by(user: current_user, course: @course)
    # renders take.json.jbuilder (the taken claim), so the SPA can transition.
  end

  # Slug-less entry: send the student into the inferred course's SPA exercise,
  # or ask which course when we can't tell.
  def entry
    course = inferred_course
    return render(:course_picker) if course.nil?
    redirect_to "/courses/#{course.slug}/verify_claim"
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
