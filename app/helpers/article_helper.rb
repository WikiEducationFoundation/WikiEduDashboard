# frozen_string_literal: true

#= Helpers for article views
module ArticleHelper
  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/CyclomaticComplexity
  def rating_priority(rating)
    rating = default_class(rating)
    case rating
    when 'fa'
      0
    when 'fl'
      1
    when 'a'
      2
    when 'ga'
      3
    when 'b'
      4
    when 'c'
      5
    when 'start'
      6
    when 'stub'
      7
    when 'list'
      8
    when nil
      9
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/CyclomaticComplexity

  def rating_display(rating)
    rating = default_class(rating)
    return nil if rating.nil?
    return rating if %w[fa ga fl].include? rating
    return rating[0] # use the first letter of the rating as the abbreviated version
  end

  # Maps international rating strings to standardized article classes.
  # Covers wikis with confirmed PageAssessments API support:
  # Arabic, Chinese, French, Hungarian, Turkish.
  INTERNATIONAL_RATING_MAP = {
    # A-class composite
    'a/ga' => 'a',
    # Featured article equivalents
    'adq' => 'fa', 'sm' => 'fa', 'seçkin_madde' => 'fa',
    'kitüntetett' => 'fa', 'م.مخ' => 'fa', '典范条目' => 'fa',
    # Featured list equivalents
    '特色列表' => 'fl',
    # Good article equivalents
    'ba' => 'ga', 'km' => 'ga', 'kaliteli_madde' => 'ga',
    'színvonalas' => 'ga', 'أ' => 'ga', '优良条目' => 'ga',
    # A-class equivalents
    '甲级条目' => 'a',
    # B-class equivalents
    'bplus' => 'b', 'ii' => 'b', 'teljes' => 'b', 'ب' => 'b', '乙级条目' => 'b',
    # C-class equivalents
    'iii' => 'c', 'jól használható' => 'c', 'ج' => 'c', '丙级条目' => 'c',
    # Start-class equivalents
    'bd' => 'start', 'iv' => 'start', 'vázlatos' => 'start', 'بداية' => 'start', '初级条目' => 'start',
    # Stub-class equivalents
    'taslak' => 'stub', 'e' => 'stub', 's' => 'stub', 'születő' => 'stub', 'بذرة' => 'stub', '小作品级条目' => 'stub',
    # List-class equivalents
    'al' => 'list', 'bl' => 'list', 'cl' => 'list', 'sl' => 'list', '列表级条目' => 'list'
  }.freeze

  def default_class(rating)
    return rating if %w[fa fl a ga b c start stub list].include? rating
    INTERNATIONAL_RATING_MAP[rating]
  end

  def calculate_view_count(first_revision, ac_views, article_views, view_count)
    # There are currently three different methods to count article views. Two of them
    # are legacy. This method tries to be backward compatible.
    #
    # The view_count AC field is no longer used in the timeslice system.
    # We use it as a hack to display article views for historical courses
    # that will not receive a new update in the timeslice system.
    #
    # Note also that average_views from ArticlesCourses records takes precedence over
    # average_views from Articles. However, for courses where the ArticlesCourses.average_views
    # field is not populated, we fall back to using average_views from the Articles table.

    average_views = ac_views || article_views
    return view_count if first_revision.nil? || average_views.nil?
    days = (Time.now.utc.to_date - first_revision.to_date).to_i
    (days * average_views).to_i
  end
end
