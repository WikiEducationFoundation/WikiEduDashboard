# frozen_string_literal: true

# Lists articles a student can choose from for the claim-verification exercise:
# articles that PAST-term courses worked on, preferring courses in the same
# subject as the student's course and falling back to all ended courses. Pure
# DB query — no harvesting; the chosen article is harvested on demand.
class RelevantArticlesForCourse
  attr_reader :articles

  DEFAULT_LIMIT = 50

  def initialize(course, limit: DEFAULT_LIMIT)
    @course = course
    @limit = limit
    @articles = by_subject.presence || general
  end

  private

  def by_subject
    return Article.none if @course.subject.blank?
    from_courses(Course.ended.where(subject: @course.subject))
  end

  def general
    from_courses(Course.ended)
  end

  def from_courses(courses_scope)
    Article.live.namespace(Article::Namespaces::MAINSPACE)
           .joins(:courses).merge(courses_scope).includes(:wiki).distinct.limit(@limit)
  end
end
