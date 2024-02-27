# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

#= Presenter for courses / campaign view
class CoursesPresenter
  attr_reader :current_user, :campaign_param

  def initialize(current_user:, campaign_param: nil, courses_list: nil, page: nil, tag: nil)
    @current_user = current_user
    @campaign_param = campaign_param
    @page = page
    @tag = tag
    @courses_list = courses_list || campaign_courses
  end

  def campaign_courses
    return unless campaign
    # Those with campaign editing rights can see the private courses
    can_remove_course? ? campaign.courses : campaign.courses.nonprivate
  end

  def user_courses
    return unless current_user
    current_user.courses.current_and_future
  end

  def campaign
    @campaign ||= Campaign.find_by(slug: campaign_param)
  end

  def campaign_articles
    return tag_articles if @tag

    articles = campaign.articles_courses.tracked
                       .includes(article: :wiki)
                       .includes(:course).where(courses: { private: false })
                       .paginate(page: @page, per_page: 100)
    # Sorting can be particularly slow for large numbers of articles.
    articles = articles.order('articles.deleted', character_sum: :desc) unless too_many_articles?
    articles
  end

  # If there are too many articles, rendering a page of them can take a very long time.
  ARTICLE_LIMIT = 50000
  def too_many_articles?
    @too_many ||= campaign.articles_courses.count > ARTICLE_LIMIT
  end

  def tag_articles
    ArticlesCourses.tracked.includes(article: :wiki)
                   .includes(:course).where(courses: { private: false })
                   .where(course: @courses_list)
                   .paginate(page: @page, per_page: 100)
  end

  def can_remove_course?
    @can_remove ||= current_user&.admin? || campaign_organizer?
  end

  alias_method :can_delete_course?, :can_remove_course?

  def campaign_organizer?
    return false unless campaign
    return @campaign_organizer if @campaign_organizer_set
    @campaign_organizer_set = true
    @campaign_organizer ||= campaign.organizers.include?(current_user)
  end

  def courses
    @courses_list
  end

  def course_count
    @course_count ||= courses.count
  end

  def active_courses
    courses.current_and_future
  end

  def search_courses(q)
    courses.joins(:instructors).includes(:instructors).where(
      'lower(title) like ? OR lower(school) like ? ' \
      'OR lower(term) like ? OR lower(username) like ?',
      "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"
    ).distinct
  end

  def courses_by_recent_edits
    # Sort first by recent edit count, and then by course title
    courses.order('recent_revision_count DESC, title').paginate(page: @page, per_page: 100)
  end

  def active_courses_by_recent_edits
    active_courses.order('recent_revision_count DESC, title').limit(100)
  end

  COURSE_SUMS_SQL = 'SUM(character_sum), ' \
                    'SUM(article_count), ' \
                    'SUM(new_article_count), ' \
                    'SUM(view_sum), ' \
                    'SUM(user_count), ' \
                    'SUM(courses.references_count)'
  def course_sums
    @course_sums ||= courses.pick(Arel.sql(COURSE_SUMS_SQL))
  end

  def word_count
    @word_count ||= WordCount.from_characters(course_sums[0] || 0)
  end

  def references_count
    course_sums[5] || 0
  end

  def article_count
    course_sums[1] || 0
  end

  def new_article_count
    course_sums[2] || 0
  end

  def view_sum
    course_sums[3] || 0
  end

  def user_count
    course_sums[4] || 0
  end

  def course_string_prefix
    campaign&.course_string_prefix || Features.default_course_string_prefix
  end

  def uploads_in_use_count
    @uploads_in_use_count ||= courses.sum(:uploads_in_use_count)
  end

  def upload_usage_count
    @upload_usage_count ||= courses.sum(:upload_usages_count)
  end

  def trained_count
    courses.sum(:trained_count)
  end

  def trained_percent
    return 100 if user_count.zero?
    100 * trained_count.to_f / user_count
  end

  def wikidata_stats
    stats ||= courses.joins(:course_stat).where.not(course_stats: nil).filter_map do |course|
      course.course_stat.stats_hash['www.wikidata.org']
    end
    return { 'www.wikidata.org' => stats.inject { |a, b| a.merge(b) { |_, x, y| x + y } } }
  end

  def creation_date
    I18n.l campaign.created_at.to_date
  end
end
