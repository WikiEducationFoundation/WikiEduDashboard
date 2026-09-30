# frozen_string_literal: true

#= Resolves a course from a pasted Dashboard course URL, a `courses/...` path,
#= or a bare course slug.
class CourseUrlParser
  # Course slugs have exactly two path segments: School/Title_(Term).
  # Anything after them (a tab such as /articles/available, a query string) is ignored.
  COURSE_PATH_MATCHER = %r{(?:\A|/)courses/(?<slug>[^/?#]+/[^/?#]+)}

  def initialize(input)
    @input = input.to_s.strip
  end

  def slug
    return if @input.empty?
    match = @input.match(COURSE_PATH_MATCHER)
    raw_slug = match ? match[:slug] : bare_slug
    # Pasted URLs carry percent-encoded parentheses. Only %XX escapes are decoded,
    # so a literal '+' in a slug is preserved.
    URI::DEFAULT_PARSER.unescape(raw_slug.delete_suffix('.json'))
  end

  def course
    return unless slug
    Course.find_by(slug:)
  end

  private

  def bare_slug
    @input.delete_prefix('/').delete_suffix('/')
  end
end
