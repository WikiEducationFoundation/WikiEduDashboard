# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

#= Presenter for building and filtering the courses list on a campaign's /programs page
class CampaignProgramsPresenter
  RANGE_FILTERS = {
    'creation'   => %i[creation_start creation_end],
    'start'      => %i[start_date_start start_date_end],
    'revisions'  => %i[revisions_min revisions_max],
    'word_count' => %i[word_count_min word_count_max],
    'references' => %i[references_min references_max],
    'views'      => %i[views_min views_max],
    'editors'    => %i[users_min users_max]
  }.freeze

  def initialize(courses:, page:, sort_column:, sort_direction:)
    @courses = courses
    @page = page
    @sort_column = sort_column
    @sort_direction = sort_direction
  end

  # Returns a human-readable summary of the active filters for display in the view.
  def build_search_terms(filters)
    parts = []
    parts << "title: #{filters[:title_query]}" if filters[:title_query].present?
    parts << "school: #{filters[:school]}" if filters[:school].present?

    RANGE_FILTERS.each do |label, (min, max)|
      parts << build_range_term(label, filters[min], filters[max])
    end

    parts.compact.join(', ')
  end

  def filter_courses(filters)
    scope = filter_courses_by_text(@courses, filters)
    scope = filter_courses_by_integer_ranges(scope, filters)
    scope = filter_courses_by_time_ranges(scope, filters)

    scope.distinct.order(courses_order_clause).paginate(page: @page, per_page: 25)
  end

  private

  def courses_order_clause
    unless @sort_column.present? && @sort_direction.present?
      return 'recent_revision_count DESC, title ASC'
    end

    order_clause = "#{@sort_column} #{@sort_direction.upcase}"
    order_clause += ', title ASC' unless @sort_column == 'title'
    order_clause
  end

  def build_range_term(label, min, max)
    return nil if min.blank? && max.blank?
    "#{label}: #{min} - #{max}"
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

  def filter_title(scope, title_query)
    return scope unless title_query.present?

    q = title_query.downcase
    scope.left_joins(:instructors).where(
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

  def parse_int(int_str)
    return nil if int_str.blank?
    Integer(int_str)
  rescue ArgumentError, TypeError
    nil
  end

  def parse_time(time_str, method)
    return nil if time_str.blank?
    Time.zone.parse(time_str)&.public_send(method)
  rescue ArgumentError
    nil
  end
end
