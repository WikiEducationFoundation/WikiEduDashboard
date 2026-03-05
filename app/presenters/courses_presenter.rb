# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"
require_dependency "#{Rails.root}/lib/analytics/histogram_plotter"

#= Presenter for courses / campaign view
class CoursesPresenter
  attr_reader :current_user, :campaign_param

  def initialize(current_user:, campaign_param: nil, courses_list: nil, page: nil, tag: nil,
                 articles_title: nil, course_title: nil, char_added_from: nil, char_added_to: nil,
                 references_count_from: nil, references_count_to: nil,
                 view_count_from: nil, view_count_to: nil, school: nil,
                 sort_column: nil, sort_direction: nil)
    @current_user = current_user
    @campaign_param = campaign_param
    @page = page
    @tag = tag
    @articles_title = articles_title
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

  PER_PAGE = 25
  # Returns a scoped query for ranked articles_courses using a deferred join via RankedArticlesCoursesQuery # rubocop:disable Layout/LineLength
  def articles_courses_scope
    @articles_courses_scope ||= Query::RankedArticlesCoursesQuery.new(
      **ranked_articles_courses_query_params
    ).scope
  end

  def ranked_articles_courses_query_params
    base_query_params.merge(filter_query_params)
  end

  def base_query_params
    {
      courses: course_ids_and_slugs,
      per_page: PER_PAGE,
      offset:,
      too_many: too_many_articles?,
      sort_column: @sort_column,
      sort_direction: @sort_direction
    }
  end

  def filter_query_params
    {
      article_title: @articles_title,
      course_title: @course_title,
      char_added_from: @char_added_from,
      char_added_to: @char_added_to,
      references_count_from: @references_count_from,
      references_count_to: @references_count_to,
      view_count_from: @view_count_from,
      view_count_to: @view_count_to,
      school: @school
    }
  end

  # Fetch and index articles by ID for efficient lookup
  def fetched_articles
    return @fetched_articles unless @fetched_articles.nil?

    @fetched_articles = Article
                        .includes(:wiki)
                        .where(id: articles_courses_scope.map(&:article_id).uniq)
                        .select(:id, :title, :deleted, :wiki_id, :namespace, :average_views)
                        .index_by(&:id)
  end

  # Create paginated collection for articles_courses data
  def paginated_articles_courses
    WillPaginate::Collection.create(current_page, PER_PAGE, campaign_articles_count) do |pager|
      pager.replace(articles_courses_scope)
    end
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
    @too_many ||= campaign_articles_count > ARTICLE_LIMIT
  end

  def campaign_articles_count
    @campaign_articles_count ||= campaign.articles_courses.where(tracked: true).count
  end

  def tag_articles
    ArticlesCourses.tracked.includes(article: :wiki)
                   .includes(:course).where(courses: { private: false })
                   .where(course: @courses_list)
                   .paginate(page: @page, per_page: 25)
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
    ).distinct.paginate(page: @page, per_page: 25)
  end

  def search_courses_by_title(q)
    courses.where('lower(title) like ?', "%#{q.downcase}%").distinct
  end

  def search_courses_by_creation_date(start_str, end_str)
    start_time = parse_time(start_str, :beginning_of_day)
    end_time = parse_time(end_str, :end_of_day)
    apply_required_range_filter(courses, 'courses.created_at', start_time, end_time)
  end

  def search_courses_by_start_date(start_str, end_str)
    start_time = parse_time(start_str, :beginning_of_day)
    end_time = parse_time(end_str, :end_of_day)
    apply_required_range_filter(courses, 'courses.start', start_time, end_time)
  end

  def search_courses_by_school(school)
    return courses.none if school.blank?
    courses.where(school: school).distinct
  end

  def school_options
    courses.where.not(school: [nil, '']).group(:school).order(:school).pluck(:school)
  end

  def course_title_options
    courses.order(:title).pluck(:title).uniq
  end

  def search_courses_by_revisions(min_str, max_str)
    min_val = parse_int(min_str)
    max_val = parse_int(max_str)
    apply_required_range_filter(courses, 'courses.recent_revision_count', min_val, max_val)
  end

  def filter_courses(filters)
    scope = filter_courses_by_text(courses, filters)
    scope = filter_courses_by_integer_ranges(scope, filters)
    scope = filter_courses_by_time_ranges(scope, filters)

    scope.distinct.order(courses_order_clause).paginate(page: @page, per_page: 25)
  end

  def courses_order_clause
    unless @sort_column.present? && @sort_direction.present?
      return 'recent_revision_count DESC, title ASC'
    end

    order_clause = "#{@sort_column} #{@sort_direction.upcase}"
    order_clause += ', title ASC' unless @sort_column == 'title'
    order_clause
  end

  def filter_courses_by_text(scope, filters)
    scope = filter_title(scope, filters[:title_query])
    scope = scope.where(school: filters[:school]) if filters[:school].present?
    scope
  end

  def filter_courses_by_integer_ranges(scope, filters)
    scope = filter_integer_range(scope, filters, :revisions_min, :revisions_max,
                                 'courses.recent_revision_count')
    scope = filter_integer_range(scope, filters, :word_count_min, :word_count_max,
                                 'courses.character_sum',
                                 multiplier: WordCount::HALFAK_EN_WIKI_ESTIMATE)
    scope = filter_integer_range(scope, filters, :references_min, :references_max,
                                 'courses.references_count')
    scope = filter_integer_range(scope, filters, :views_min, :views_max, 'courses.view_sum')
    filter_integer_range(scope, filters, :users_min, :users_max, 'courses.user_count')
  end

  def filter_courses_by_time_ranges(scope, filters)
    scope = filter_time_range(scope, filters, :creation_start, :creation_end, 'courses.created_at')
    filter_time_range(scope, filters, :start_date_start, :start_date_end, 'courses.start')
  end

  def courses_by_recent_edits
    # Sort first by recent edit count, and then by course title
    # courses.order('recent_revision_count DESC, title').paginate(page: @page, per_page: 1)
    filter_courses({})
  end

  def active_courses_by_recent_edits
    active_courses.order('recent_revision_count DESC, title').limit(100)
  end

  COURSE_SUMS_SQL = 'SUM(character_sum), ' \
                    'SUM(article_count), ' \
                    'SUM(new_article_count), ' \
                    'SUM(view_sum), ' \
                    'SUM(user_count), ' \
                    'SUM(courses.references_count), ' \
                    'SUM(uploads_in_use_count), ' \
                    'SUM(upload_usages_count), ' \
                    'SUM(trained_count), ' \
                    'SUM(upload_count), ' \
                    'COUNT(*)'
  def course_sums
    @course_sums ||= if campaign
                       Rails.cache.fetch(campaign.course_sums_cache_key, expires_in: 1.day) do
                         courses.pick(Arel.sql(COURSE_SUMS_SQL))
                       end
                     else
                       courses.pick(Arel.sql(COURSE_SUMS_SQL))
                     end
  end

  def word_count
    @word_count ||= WordCount.from_characters(course_sums[0] || 0)
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

  def references_count
    course_sums[5] || 0
  end

  def uploads_in_use_count
    course_sums[6] || 0
  end

  def upload_usage_count
    course_sums[7] || 0
  end

  def trained_count
    course_sums[8] || 0
  end

  def upload_count
    course_sums[9] || 0
  end

  def courses_count
    course_sums[10] || 0
  end

  def course_string_prefix
    campaign&.course_string_prefix || Features.default_course_string_prefix
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
    @stats ||= courses.includes(:course_stat).where.not(course_stat: nil).filter_map do |course|
      course.course_stat&.stats_hash&.[]('www.wikidata.org')
    end

    { 'www.wikidata.org' => @stats.inject { |a, b| a.merge(b) { |_, x, y| x + y } } }
  end

  def creation_date
    I18n.l campaign.created_at.to_date
  end

  private

  def parse_int(int_str)
    return nil if int_str.blank?
    Integer(int_str)
  rescue StandardError
    nil
  end

  def parse_time(time_str, method)
    return nil if time_str.blank?
    Time.zone.parse(time_str)&.public_send(method)
  rescue StandardError
    nil
  end

  def apply_required_range_filter(scope, column, min_val, max_val)
    if min_val && max_val
      scope.where("#{column} BETWEEN ? AND ?", min_val, max_val).distinct
    elsif min_val
      scope.where("#{column} >= ?", min_val).distinct
    elsif max_val
      scope.where("#{column} <= ?", max_val).distinct
    else
      scope.none
    end
  end

  def apply_optional_range_filter(scope, column, min_val, max_val)
    if min_val && max_val
      scope.where("#{column} BETWEEN ? AND ?", min_val, max_val)
    elsif min_val
      scope.where("#{column} >= ?", min_val)
    elsif max_val
      scope.where("#{column} <= ?", max_val)
    else
      scope
    end
  end

  def filter_title(scope, title_query)
    return scope unless title_query.present?

    q = title_query.downcase
    scope.joins(:instructors).includes(:instructors).where(
      'lower(title) like ? OR lower(school) like ? OR lower(term) like ? OR ' \
      'lower(username) like ?', "%#{q}%", "%#{q}%", "%#{q}%", "%#{q}%"
    )
  end

  def filter_integer_range(scope, filters, min_key, max_key, column, multiplier: 1)
    return scope unless filters[min_key].present? || filters[max_key].present?

    min_val = parse_int(filters[min_key])
    max_val = parse_int(filters[max_key])

    min_val = (min_val.to_f * multiplier).to_i if min_val && multiplier != 1
    max_val = (max_val.to_f * multiplier).to_i if max_val && multiplier != 1

    apply_optional_range_filter(scope, column, min_val, max_val)
  end

  def filter_time_range(scope, filters, start_key, end_key, column)
    return scope unless filters[start_key].present? || filters[end_key].present?

    start_val = parse_time(filters[start_key], :beginning_of_day)
    end_val = parse_time(filters[end_key], :end_of_day)

    apply_optional_range_filter(scope, column, start_val, end_val)
  end
end
