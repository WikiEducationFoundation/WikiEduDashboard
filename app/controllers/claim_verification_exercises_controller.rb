# frozen_string_literal: true

# Drives the student claim-verification exercise (issue #6910).
# - GET show: if the student has taken a claim, show it; otherwise (or when they
#   ask to choose again) let them pick an article from prior subject-matched
#   courses and browse its cited claims. Reached course-scoped (from the
#   timeline) or slug-less (from the exercise module, inferring the course — a
#   course picker when it can't tell).
# - POST take: persist the chosen claim and record it as their assignment.
# Articles are harvested on demand; only the taken claim is persisted. The
# student does the verification in their sandbox; nothing they produce is stored.
class ClaimVerificationExercisesController < ApplicationController
  before_action :require_signed_in

  def show
    @course = course_from_slug || inferred_course
    return render(:course_picker) if @course.nil?

    @assignment = VerificationClaimAssignment.find_by(user: current_user, course: @course)
    render_exercise
  end

  def take
    @course = course_from_slug
    TakeVerificationClaim.new(user: current_user, course: @course,
                              article: Article.find(params[:article_id]),
                              sentence: params[:sentence], ref_id: params[:ref_id])
    redirect_to "/courses/#{@course.slug}/verify_claim"
  end

  private

  # Pick the screen: a chosen claim's detail, the highlighted article prose, the
  # already-taken claim, or the article picker.
  def render_exercise
    return render_claim_detail if params[:article_id].present? && params[:sentence].present?
    return render_article_prose if params[:article_id].present?
    return render_taken_claim if @assignment && params[:choose].blank?

    render_article_list
  end

  def render_taken_claim
    @claim = @assignment.verification_claim
    render :show
  end

  def render_article_list
    @articles = RelevantArticlesForCourse.new(@course).articles
    render :articles
  end

  # The article's prose, with cited claims highlighted to browse and pick from.
  def render_article_prose
    @article = Article.find(params[:article_id])
    @extraction = ExtractArticleClaims.new(@article)
    render :claims
  end

  # One chosen claim with its cited source(s) and a take action.
  def render_claim_detail
    @article = Article.find(params[:article_id])
    @extraction = ExtractArticleClaims.new(@article)
    @claim = @extraction.claims.find { |claim| claim.sentence == params[:sentence] }
    @citations = claim_citations(@claim)
    render :claim
  end

  def claim_citations(claim)
    return [] if claim.nil?
    @extraction.citations.select { |citation| claim.ref_ids.include?(citation.ref_id) }
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
