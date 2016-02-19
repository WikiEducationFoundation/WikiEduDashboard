#= Imports and updates ratings for articles
class RatingImporter
  ################
  # Entry points #
  ################
  def self.update_all_ratings
    articles = Article.current.live
               .namespace(0)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.update_new_ratings
    articles = Article.current
               .where(rating_updated_at: nil).namespace(0)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  ##############
  # API Access #
  ##############
  def self.update_ratings(all_articles)
    require './lib/wiki_api'
    all_articles.group_by(&:wiki).each do |wiki, articles|
      titles = articles.pluck(:title)
      ratings = WikiApi.new(wiki).get_article_rating(titles).inject(&:merge)
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
end
