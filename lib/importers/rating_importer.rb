#= Imports and updates ratings for articles
class RatingImporter
  ################
  # Entry points #
  ################
  def self.update_all_ratings
    # Since the rating scraper is only based on the English Wikipedia 1.0 rating
    # system, we only include articles from en.wiki.
    # If we develop scrapers for other languages that also keep track of ratings
    # via talk page templates, this will need to be overhauled.
    wiki_id = en_wiki.id
    articles = Article.current.live
               .namespace(0)
               .where(wiki_id: wiki_id)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.update_new_ratings
    wiki_id = en_wiki.id # English Wikipedia only, see above.
    articles = Article.current
               .where(rating_updated_at: nil).namespace(0)
               .where(wiki_id: wiki_id)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  ##############
  # API Access #
  ##############
  def self.update_ratings(article_groups)
    require './lib/wiki_api'
    article_groups.with_index do |articles, _batch|
      titles = articles.map(&:title)
      # NOTE: English Wikipedia only, per above.
      ratings = WikiApi.new(en_wiki).get_article_rating(titles).inject(&:merge)
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
