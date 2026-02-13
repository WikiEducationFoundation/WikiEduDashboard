# frozen_string_literal: true

#= Imports and updates ratings for articles
class RatingImporter
  ################
  # Entry points #
  ################

  # MediaWiki allows a maximum of 50 values in the "titles" parameter.
  API_MAX_TITLES = 50

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
    # We support multi-wiki updates on-demand, but bulk updates are still
    # limited to English Wikipedia for performance reasons.
    # To avoid excessive load from frequent on-demand updates on non-English
    # wikis, skip the update if the rating was refreshed very recently.
    if article.wiki_id != en_wiki.id &&
       article.rating_updated_at.present? &&
       article.rating_updated_at > 5.minutes.ago
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
