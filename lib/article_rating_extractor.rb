# frozen_string_literal: true

#= Fetches article classes from PageAssessments response
# We simplify this parser by folding the nonstandard ratings
# into the corresponding standard ones. We don't want to deal with edge cases
# like bplus and a/ga.

class ArticleRatingExtractor
  def initialize(pageassessments)
    @assessments = pageassessments || {}
  end

  ################
  # Entry point #
  ################

  def ratings
    # Returns the classes of articles mapped to the respective title
    ratings = {}
    @assessments.each_value do |page|
      title = page['title'].tr(' ', '_')
      ratings[title] ||= get_article_class(page['pageassessments'])
    end
    return ratings
  end

  private

  # Returns the first wikiproject rating returned.
  # These are usually the same across all projects that have a rating.
  def get_article_class(pageassessments)
    # Returns nil if no page assessment data found
    return nil if pageassessments.nil?
    info = pageassessments.values.first
    # The api returns '' when there is no rating
    return info['class'].downcase.empty? ? nil : info['class'].downcase
  end
end
