# frozen_string_literal: true

# Infers the course a user came from, using an explicit `return_to` param or
# the `training_return_to` path that TrainingController stores in the session
# (from `return_to` or the referer). Shared by TrainingController (course
# context for the Get Help button) and ClaimVerificationExercisesController
# (the slug-less entry funnel).
module CourseFromReturnTo
  extend ActiveSupport::Concern

  private

  def course_from_return_to
    path = params[:return_to].presence || session[:training_return_to]
    return if path.blank?
    slug = slug_from_course_path(path)
    Course.find_by(slug:) if slug.present?
  end

  # "/courses/School/Title_(Term)/timeline" -> "School/Title_(Term)".
  # Takes a bare path or a full URL (a referer), raw or percent-encoded.
  # Course slugs are exactly school/title (one slash), so take the two
  # segments after "courses". Decodes with URI.decode_uri_component rather
  # than CGI.unescape, because "+" is literal in a path.
  def slug_from_course_path(path)
    segments = path.split(/[?#]/, 2).first.to_s.split('/').compact_blank
    index = segments.index('courses')
    return if index.nil?
    slug = URI.decode_uri_component(segments[index + 1, 2].to_a.join('/'))
    slug if slug.valid_encoding?
  rescue ArgumentError # malformed %-encoding
    nil
  end
end
