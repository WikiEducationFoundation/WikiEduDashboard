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
    if %w[fa ga fl].include? rating
      return rating
    else
      return rating[0] # use the first letter of the rating as the abbreviated version
    end
  end

  def default_class(rating)
    # Handles the different article classes and returns a known article class
    if %w[fa fl a ga b c start stub list].include? rating
      return rating
    elsif rating.eql? 'bplus'
      return 'b'
    elsif rating.eql? 'a/ga'
      return 'a'
    elsif %w[al bl cl sl].include? rating
      return 'list'
    else
      return nil
    end
  end
end
