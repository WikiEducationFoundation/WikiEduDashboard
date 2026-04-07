# frozen_string_literal: true

# RankedArticlesCoursesQuery builds a subquery and join scope for retrieving articles_courses
# with optional ordering, pagination, and filtering for tracked articles only.
# This is used to cleanly separate query logic from presenter code.
# It uses a deferred join via a subquery for improved performance on large datasets.
class Query::RankedArticlesCoursesQuery
  def initialize(courses:, per_page:, offset:, too_many:, sort_column: nil, sort_direction: nil)
    @courses = courses
    @per_page = per_page
    @offset = offset
    @too_many = too_many
    @sort_column = sort_column
    @sort_direction = sort_direction
  end

  # Builds the final scope by joining the subquery on ID, used to fetch paginated and ranked results. # rubocop:disable Layout/LineLength
  def scope
    ArticlesCourses
      .joins("INNER JOIN (#{subquery.to_sql}) AS ranked_articles USING (id)")
      .select(:article_id, :course_id, :character_sum, :references_count,
              :first_revision, :average_views, :view_count, :updated_at)
  end

  private

  SORTABLE_COLUMNS = %w[title view_sum character_sum references_count].freeze
  DEFAULT_ORDER = 'articles.deleted ASC, articles_courses.character_sum DESC'

  # Builds a subquery that includes optional ordering and pagination depending on the "too_many" flag. # rubocop:disable Layout/LineLength
  def subquery
    ArticlesCourses
      .includes(:article)
      .where(course_id: @courses.map(&:id), tracked: true)
      .select(:id)
      .then { |q| @too_many ? q : q.order(order_clause) }
      .limit(@per_page)
      .offset(@offset)
  end

  def order_clause
    if @sort_column.present? && @sort_direction.present? &&
       SORTABLE_COLUMNS.include?(@sort_column)
      "#{@sort_column} #{@sort_direction.upcase}"
    else
      DEFAULT_ORDER
    end
  end
end
