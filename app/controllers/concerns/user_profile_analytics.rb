# frozen_string_literal: true

module UserProfileAnalytics
  extend ActiveSupport::Concern

  def max_project
    ids_array = public_courses.map(&:home_wiki_id)
    max_ids = ids_array.tally.select { |_k, v| v == ids_array.tally.values.max }.keys
    projects = Wiki.where(id: max_ids).map(&:project)
    projects.include?('wikipedia') ? 'wikipedia' : projects[0]
  end

  def get_articles_by_language
    courses_users = student_courses_users
    course_ids = courses_users.map(&:course_id).uniq
    return [] if course_ids.empty?

    articles_count_by_course = student_articles_count_by_course(course_ids)
    grouped = group_contributions_by_language(courses_users, articles_count_by_course)
    format_language_stats(grouped)
  end

  def fetch_user_articles(course_id = nil)
    course_ids = student_course_ids
    course_ids &= [course_id.to_i] if course_id.present?
    return ArticlesCourses.none if course_ids.empty?

    ArticlesCourses
      .tracked
      .where(course_id: course_ids)
      .where('user_ids LIKE ?', "%- #{@user.id}\n%")
      .joins(:article, :course)
      .where(articles: { deleted: false, namespace: Article::Namespaces::MAINSPACE })
      .includes(:article, :course, article: :wiki)
  end

  def fetch_user_article_stats(course_ids)
    return {} if course_ids.empty?

    ArticleCourseUserWikiTimeslice
      .where(user_id: @user.id, course_id: course_ids)
      .group_by { |r| [r.course_id, r.article_id] }
      .transform_values do |rows|
        {
          character_sum: rows.sum { |r| r.character_sum.to_i },
          references_count: rows.sum { |r| r.references_count.to_i },
          new_article: rows.any?(&:new_article)
        }
      end
  end

  def courses_with_acuwt(course_ids)
    return Set.new if course_ids.empty?

    ArticleCourseUserWikiTimeslice
      .where(course_id: course_ids)
      .distinct
      .pluck(:course_id)
      .to_set
  end

  def public_courses
    @user.courses.nonprivate
  end

  private

  def student_course_ids
    @student_course_ids ||= student_courses_users.pluck(:course_id)
  end

  def student_courses_users
    @user.courses_users
         .includes(course: :home_wiki)
         .joins(:course)
         .where(courses: { private: false }, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  def student_articles_count_by_course(course_ids)
    ArticlesCourses
      .tracked
      .where(course_id: course_ids)
      .where('user_ids LIKE ?', "%- #{@user.id}\n%")
      .joins(:article)
      .where(articles: { deleted: false, namespace: Article::Namespaces::MAINSPACE })
      .group(:course_id)
      .count
  end

  def group_contributions_by_language(courses_users, articles_count_by_course)
    courses_users.each_with_object({}) do |cu, grouped|
      key, lang_data = init_language_bucket(cu)
      grouped[key] ||= lang_data
      grouped[key][:character_sum] += cu.character_sum_ms.to_i
      grouped[key][:references_count] += cu.references_count.to_i
      grouped[key][:article_count] += articles_count_by_course[cu.course_id].to_i
    end
  end

  def init_language_bucket(courses_user)
    wiki = courses_user.course.home_wiki
    language = wiki&.language || 'unknown'
    project = wiki&.project || 'unknown'
    ["#{language}-#{project}", { language:, project:, character_sum: 0,
                                 references_count: 0, article_count: 0 }]
  end

  def format_language_stats(grouped)
    grouped.values.map do |v|
      {
        language: v[:language],
        project: v[:project],
        word_count: WordCount.from_characters(v[:character_sum]),
        references_count: v[:references_count],
        article_count: v[:article_count]
      }
    end.sort_by { |v| -v[:word_count] }
  end
end