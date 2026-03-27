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

  # Builds a subquery that includes optional ordering and pagination depending on the "too_many" flag. # rubocop:disable Layout/LineLength
  def subquery
    ArticlesCourses
      .includes(:article)
      .where(course_id: @courses.map(&:id), tracked: true)
      .select(:id)
      .then do |q|
        if @sort_column.present? && @sort_direction.present?
          if %w[title view_sum character_sum references_count].include?(@sort_column)
            # Some columns might need manual mapping depending on the query,
            # but generally we can use order
            order_string = "#{@sort_column} #{@sort_direction.upcase}"
            @too_many ? q : q.order(order_string)
          else
            # fallback to default
            @too_many ? q : q.order('articles.deleted ASC, articles_courses.character_sum DESC')
          end
        else
          @too_many ? q : q.order('articles.deleted ASC, articles_courses.character_sum DESC')
        end
      end
      .limit(@per_page)
      .offset(@offset)
  end
end
