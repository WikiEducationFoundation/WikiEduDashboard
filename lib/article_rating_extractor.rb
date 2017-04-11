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
    @assessments.values.each do |page|
    # The class of the first pageassessment is taken
      rating =  ratings[page['title'].tr(' ', '_')]
      ratings[page['title'].tr(' ', '_')] ||= get_article_class(page['pageassessments'])
    end
    return ratings
  end

  private

  def get_article_class(pageassessments)
    # Returns nil if no page assessment data found
    return nil if pageassessments.nil?
    info = pageassessments.values.first
      # Returns the class of the first project as article class is same under all projects
      # The api returns '' when there is no rating
    return info['class'].downcase.empty? ? nil : info['class'].downcase
  end

end
