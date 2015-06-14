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
  def self.update_ratings(articles)
    require './lib/wiki'
    articles.with_index do |group, _batch|
      ratings = Wiki.get_article_rating(group.map(&:title)).inject(&:merge)
      next if ratings.blank?
      group.each do |article|
        article.rating = ratings[article.title]
        article.rating_updated_at = Time.now
      end
      group.each(&:save)
    end
  end
end
