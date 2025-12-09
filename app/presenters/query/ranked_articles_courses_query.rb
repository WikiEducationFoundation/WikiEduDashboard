# frozen_string_literal: true

# RankedArticlesCoursesQuery builds a subquery and join scope for retrieving articles_courses
# with optional ordering, pagination, and filtering for tracked articles only.
# This is used to cleanly separate query logic from presenter code.
# It uses a deferred join via a subquery for improved performance on large datasets.
class Query::RankedArticlesCoursesQuery
  def initialize(courses:, per_page:, offset:, too_many:, article_title: nil, course_title: nil,
                 char_added_from: nil, char_added_to: nil,
                 references_count_from: nil, references_count_to: nil,
                 view_count_from: nil, view_count_to: nil)
    @courses = courses
    @per_page = per_page
    @offset = offset
    @too_many = too_many
    @article_title = article_title
    @course_title = course_title
    @char_added_from = char_added_from
    @char_added_to = char_added_to
    @references_count_from = references_count_from
    @references_count_to = references_count_to
    @view_count_from = view_count_from
    @view_count_to = view_count_to
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
      .includes(:article, :course)
      .where(course_id: @courses.map(&:id), tracked: true)
      .then { |q| @article_title ? q.where('articles.title LIKE ?', "%#{@article_title}%") : q }
      .then { |q| @course_title ? q.where('courses.title LIKE ?', "%#{@course_title}%") : q }
      .then do |q|
      if @char_added_from.present?
        q.where('articles_courses.character_sum >= ?',
                @char_added_from)
      else
        q
      end
    end
      .then do |q|
      if @char_added_to.present?
        q.where('articles_courses.character_sum <= ?',
                @char_added_to)
      else
        q
      end
    end
      .then do |q|
      if @references_count_from.present?
        q.where('articles_courses.references_count >= ?',
                @references_count_from)
      else
        q
      end
    end
      .then do |q|
      if @references_count_to.present?
        q.where('articles_courses.references_count <= ?',
                @references_count_to)
      else
        q
      end
    end
      .then do |q|
      if @view_count_from.present?
        q.where('articles_courses.view_count >= ?',
                @view_count_from)
      else
        q
      end
    end
      .then do |q|
      if @view_count_to.present?
        q.where('articles_courses.view_count <= ?',
                @view_count_to)
      else
        q
      end
    end
      .select(:id)
      .then do |q|
        @too_many ? q : q.order('articles.deleted ASC, articles_courses.character_sum DESC')
      end
      .limit(@per_page)
      .offset(@offset)
  end
end
