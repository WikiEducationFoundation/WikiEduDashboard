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

  def default_class(rating)
    # Handles the different article classes and returns a known article class
    return rating if %w[fa fl a ga b c start stub list].include? rating
    return 'b' if rating.eql? 'bplus'
    return 'a' if rating.eql? 'a/ga'
    return 'list' if %w[al bl cl sl].include? rating
    return nil
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
