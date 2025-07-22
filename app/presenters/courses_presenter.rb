# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"
require_dependency "#{Rails.root}/app/presenters/query/ranked_articles_courses_query"

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

  MAX_COURSE_COUNT = 500
  def too_large?
    return false unless campaign
    return false if Features.wiki_ed?
    @course_count ||= campaign.courses.count
    @course_count > MAX_COURSE_COUNT
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

    {
      articles_courses: paginated_articles_courses,
      courses: course_ids_and_slugs.index_by(&:id),
      articles: fetched_articles
    }
  end

  # Fetch course IDs associated with the campaign
  def campaigns_courses_ids
    @campaigns_courses_ids ||= CampaignsCourses.where(campaign_id: campaign.id).select(:course_id).pluck(:course_id) # rubocop:disable Layout/LineLength
  end

  # Load only needed course data, grouped by ID
  def course_ids_and_slugs
    @course_ids_and_slugs ||= Course.where(id: campaigns_courses_ids, private: false).select(:id,
                                                                                             :slug)
  end

  PER_PAGE = 100
  # Returns a scoped query for ranked articles_courses using a deferred join via RankedArticlesCoursesQuery # rubocop:disable Layout/LineLength
  def articles_courses_scope
    return @articles_courses_scope unless @articles_courses_scope.nil?

    @articles_courses_scope = RankedArticlesCoursesQuery.new(
      courses: course_ids_and_slugs,
      per_page: PER_PAGE,
      offset:,
      too_many: too_many_articles?
    ).scope
  end

  # Fetch and index articles by ID for efficient lookup
  def fetched_articles
    return @fetched_articles unless @fetched_articles.nil?

    @fetched_articles = Article
                        .includes(:wiki)
                        .where(id: articles_courses_scope.map(&:article_id).uniq)
                        .select(:id, :title, :deleted, :wiki_id, :namespace)
                        .index_by(&:id)
  end

  # Create paginated collection for articles_courses data
  def paginated_articles_courses
    WillPaginate::Collection.create(current_page, PER_PAGE, total_articles_count) do |pager|
      pager.replace(articles_courses_scope)
    end
  end

  # Count total articles for pagination metadata
  def total_articles_count
    ArticlesCourses.where(course_id: course_ids_and_slugs.map(&:id), tracked: true).count
  end

  # Current page number with fallback to 1
  def current_page
    @page.to_i < 1 ? 1 : @page.to_i
  end

  # Calculate offset for pagination
  def offset
    (current_page - 1) * PER_PAGE
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
    # The remove [from campaign] buttons are not applicable to the tagged_courses view
    return false if @tag
    @can_remove ||= current_user&.admin? || campaign_organizer?
  end

  alias can_delete_course? can_remove_course?

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
    @course_sums ||= if campaign
                       Rails.cache.fetch("#{campaign.slug}-course_sums", expires_in: 3.hours) do
                         courses.pick(Arel.sql(COURSE_SUMS_SQL))
                       end
                     else
                       courses.pick(Arel.sql(COURSE_SUMS_SQL))
                     end
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
    return combined_wikidata_stats unless campaign

    Rails.cache.fetch("#{campaign.slug}-wikidata_stats", expires_in: 3.hours) do
      combined_wikidata_stats
    end
  end

  def combined_wikidata_stats
    @stats ||= courses.includes(:course_stat).where.not(course_stats: nil).filter_map do |course|
      course.course_stat&.stats_hash&.[]('www.wikidata.org')
    end

    { 'www.wikidata.org' => @stats.inject { |a, b| a.merge(b) { |_, x, y| x + y } } }
  end

  def creation_date
    I18n.l campaign.created_at.to_date
  end
end
