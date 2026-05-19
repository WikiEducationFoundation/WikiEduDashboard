# frozen_string_literal: true

# RankedArticlesCoursesQuery builds a subquery and join scope for retrieving articles_courses
# with optional ordering, pagination, and filtering for tracked articles only.
# This is used to cleanly separate query logic from presenter code.
# It uses a deferred join via a subquery for improved performance on large datasets.
class Query::RankedArticlesCoursesQuery
  def initialize(courses:, per_page:, offset:, too_many:, article_title: nil, course_title: nil,
                 char_added_from: nil, char_added_to: nil,
                 references_count_from: nil, references_count_to: nil,
                 view_count_from: nil, view_count_to: nil, school: nil,
                 sort_column: nil, sort_direction: nil)
    @courses = courses
    @per_page = per_page
    @offset = offset
    @too_many = too_many
    @article_title = article_title
    @course_title = course_title
    @school = school
    @char_added_from = char_added_from
    @char_added_to = char_added_to
    @references_count_from = references_count_from
    @references_count_to = references_count_to
    @view_count_from = view_count_from
    @view_count_to = view_count_to
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

  def total_count
    base_subquery.count
  end

  private

  # Builds a subquery that includes optional ordering and pagination depending on the "too_many" flag. # rubocop:disable Layout/LineLength
  def subquery
    q = apply_sorting(base_subquery)
    q.limit(@per_page).offset(@offset)
  end

  def base_subquery
    q = ArticlesCourses
        .includes(:article, :course)
        .where(course_id: @courses.map(&:id), tracked: true)

    q = apply_text_filters(q)
    q = apply_range_filters(q)
    q.select(:id)
  end

  def apply_sorting(query)
    return query if @too_many

    order_clause = if @sort_column.present? && @sort_direction.present?
                     order_clause_for_articles(@sort_column, @sort_direction)
                   else
                     'articles.deleted ASC, articles_courses.character_sum DESC'
                   end
    query.order(order_clause)
  end

  def order_clause_for_articles(column, direction)
    column_map = {
      'title' => 'articles.title',
      'char_added' => 'articles_courses.character_sum',
      'references' => 'articles_courses.references_count',
      'views' => 'articles_courses.view_count'
    }

    sql_column = column_map[column] || column
    direction_sql = direction.upcase

    order_parts = ['articles.deleted ASC']

    order_parts << "#{sql_column} #{direction_sql}"

    order_parts << 'articles.title ASC' unless column == 'title'

    order_parts.join(', ')
  end

  def apply_text_filters(query)
    q = query

    if @article_title.present?
      q = q.joins(:article).where('articles.title LIKE ?', "%#{@article_title}%")
    end
    if @course_title.present?
      like = "%#{@course_title}%"
      q = q.joins(:course).where('courses.title LIKE ?', like)
    end

    if @school.present?
      school_list = Array(@school).reject(&:blank?)
      q = q.joins(:course).where(courses: { school: school_list }) if school_list.any?
    end

    q
  end

  def apply_range_filters(query)
    q = query
    q = apply_min_max(q, 'articles_courses.character_sum', @char_added_from, @char_added_to)
    q = apply_min_max(q, 'articles_courses.references_count', @references_count_from,
                      @references_count_to)
    q = apply_min_max(q, 'articles_courses.view_count', @view_count_from, @view_count_to)
    q
  end

  def apply_min_max(query, column, min_val, max_val)
    q = query
    q = q.where("#{column} >= ?", min_val) if min_val.present?
    q = q.where("#{column} <= ?", max_val) if max_val.present?
    q
  end
end
