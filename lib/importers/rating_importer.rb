# frozen_string_literal: true

#= Imports and updates ratings for articles
class RatingImporter
  ################
  # Entry points #
  ################

  # MediaWiki allows a maximum of 50 values in the "titles" parameter.
  API_MAX_TITLES = 50

  # Wikis where the PageAssessments extension is enabled and we have
  # visual mappings in ArticleHelper.
  SUPPORTED_LANGUAGES = %w[en ar fr hu tr zh].freeze

  # Minimum interval between on-demand rating refreshes for a single article.
  RATING_UPDATE_COOLDOWN = 5.minutes

  def self.update_all_ratings
    # Since the rating scraper is only based on the English Wikipedia 1.0 rating
    # system, we only include articles from en.wiki.
    # If we develop scrapers for other languages that also keep track of ratings
    # via talk page templates, this will need to be overhauled.
    wiki_id = en_wiki.id
    articles = Article.current.live
                      .namespace(0)
                      .where(wiki_id:)
                      .find_in_batches(batch_size: API_MAX_TITLES)
    update_ratings(articles)
  end

  def self.update_new_ratings
    wiki_id = en_wiki.id # English Wikipedia only, see above.
    edited_articles = Article.current
                             .where(rating_updated_at: nil).namespace(0)
                             .where(wiki_id:)
                             .find_in_batches(batch_size: API_MAX_TITLES)
    update_ratings(edited_articles)
    assigned_articles = Article.assigned
                               .where(rating_updated_at: nil).namespace(0)
                               .where(wiki_id:)
                               .find_in_batches(batch_size: API_MAX_TITLES)
    update_ratings(assigned_articles)
  end

  def self.update_rating_for_article(article)
    # Only fetch ratings for wikis where the PageAssessments API is enabled.
    return unless SUPPORTED_LANGUAGES.include?(article.wiki.language)

    # Skip if the rating was refreshed very recently to avoid excessive load.
    if article.rating_updated_at.present? &&
       article.rating_updated_at > RATING_UPDATE_COOLDOWN.ago
      return
    end
    update_ratings([[article]])
  end

  ##############
  # API Access #
  ##############
  def self.update_ratings(article_groups)
    require "#{Rails.root}/lib/wiki_api"
    article_groups.each do |articles|
      titles = articles.map(&:title)
      wiki = articles.first.wiki
      ratings = WikiApi.new(wiki).get_article_rating(titles)
      next if ratings.blank?
      update_article_ratings(articles, ratings)
    end
  end

  ####################
  # Database methods #
  ####################
  def self.update_article_ratings(articles, ratings)
    articles.each do |article|
      article.rating = ratings[article.title]
      article.rating_updated_at = Time.zone.now
    end
    Article.transaction do
      articles.each(&:save)
    end
  end

  ##################
  # Helper methods #
  ##################

  def self.en_wiki
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end
end
