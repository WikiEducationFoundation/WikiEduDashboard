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
  # The subquery picks the page; the page is ordered again here, since a join
  # returns a derived table's rows in no promised order. The articles join is
  # spelled out: Rails would alias `left_joins(:article)` because the
  # subquery's text already names the table.
  def scope
    ArticlesCourses
      .joins("INNER JOIN (#{subquery.to_sql}) AS ranked_articles " \
             'ON ranked_articles.id = articles_courses.id')
      .select(:article_id, :course_id, :character_sum, :references_count,
              :first_revision, :average_views, :view_count, :updated_at)
      .then { |q| @too_many ? q : q.joins(ARTICLES_JOIN).order(order_clause) }
  end

  ARTICLES_JOIN = 'LEFT OUTER JOIN articles ON articles.id = articles_courses.article_id'

  private

  # The views the page shows are computed per row (ArticleHelper#calculate_view_count):
  # average daily views times the days since the first revision, or the stored
  # view_count when either is missing. Ordering by the same arithmetic keeps the
  # sort in step with the numbers on screen; `articles_courses` has no `view_sum`.
  # UTC_DATE matches the helper's `Time.now.utc`, whatever the server's time zone.
  VIEWS_SQL = 'COALESCE(DATEDIFF(UTC_DATE(), articles_courses.first_revision) * ' \
              'COALESCE(articles_courses.average_views, articles.average_views), ' \
              'articles_courses.view_count)'
  # Sort parameter => SQL to order by. The keys are the names the controller accepts.
  SORT_COLUMNS = {
    'title' => 'articles.title',
    'view_sum' => VIEWS_SQL,
    'character_sum' => 'articles_courses.character_sum',
    'references_count' => 'articles_courses.references_count'
  }.freeze
  DIRECTIONS = %w[ASC DESC].freeze
  DEFAULT_ORDER = 'articles.deleted ASC, articles_courses.character_sum DESC'

  # Builds a subquery that includes optional ordering and pagination depending on the "too_many" flag. # rubocop:disable Layout/LineLength
  # The order spans the articles table, so it is joined: `includes` would make
  # Rails eager-load it and select every articles column into the subquery.
  def subquery
    ArticlesCourses
      .left_joins(:article)
      .where(course_id: @courses.map(&:id), tracked: true)
      .select(:id)
      .then { |q| @too_many ? q : q.order(order_clause) }
      .limit(@per_page)
      .offset(@offset)
  end

  def order_clause
    column = SORT_COLUMNS[@sort_column]
    direction = DIRECTIONS.find { |d| d.casecmp?(@sort_direction.to_s) }
    return DEFAULT_ORDER unless column && direction
    Arel.sql(column).public_send(direction.downcase)
  end
end
