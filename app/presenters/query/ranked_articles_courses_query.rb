# frozen_string_literal: true

# RankedArticlesCoursesQuery builds a subquery and join scope for retrieving articles_courses
# with optional ordering, pagination, and filtering for tracked articles only.
# This is used to cleanly separate query logic from presenter code.
# It uses a deferred join via a subquery for improved performance on large datasets.
class Query::RankedArticlesCoursesQuery
  def initialize(courses:, per_page:, offset:, too_many:)
    @courses = courses
    @per_page = per_page
    @offset = offset
    @too_many = too_many
  end

  # Builds the final scope by joining the subquery on ID, used to fetch paginated and ranked results. # rubocop:disable Layout/LineLength
  def scope
    ArticlesCourses
      .joins("INNER JOIN (#{subquery.to_sql}) AS ranked_articles USING (id)")
      .select(:article_id, :course_id, :character_sum, :references_count,
              :first_revision, :average_views, :view_count, :updated_at)
  end

  private

  # Builds a subquery that includes optional ordering and pagination depending on the "too_many" flag. # rubocop:disable Layout/LineLength
  def subquery
    ArticlesCourses
      .includes(:article)
      .where(course_id: @courses.map(&:id), tracked: true)
      .select(:id)
      .then do |q|
        @too_many ? q : q.order('articles.deleted ASC, articles_courses.character_sum DESC')
      end
      .limit(@per_page)
      .offset(@offset)
  end
end
