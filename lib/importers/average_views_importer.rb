# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_pageviews"

class AverageViewsImporter
  DAYS_UNTIL_OUTDATED = 14
  def self.update_outdated_average_views(articles)
    to_update = articles.where(average_views_updated_at: nil).or(
      articles.where('average_views_updated_at < ?', DAYS_UNTIL_OUTDATED.days.ago)
    )
    update_average_views(to_update)
  end

  ARTICLES_PER_BATCH = 8
  def self.update_average_views(articles)
    article_batches = articles.includes(:wiki).each_slice(ARTICLES_PER_BATCH)
    article_batches.each do |batch|
      update_average_views_for_batch batch
    end
  end

  def self.update_average_views_for_batch(articles)
    average_views = {}
    threads = articles.each_with_index.map do |article, i|
      Thread.new(i) do
        average_views[article.id] = WikiPageviews.new(article).average_views
      end
    end
    threads.each(&:join)

    datestamp = Time.zone.today
    save_updated_average_views(articles, average_views, datestamp)
  end

  def self.save_updated_average_views(articles, average_views, average_views_updated_at)
    Article.transaction do
      articles.each do |article|
        article.average_views_updated_at = average_views_updated_at
        article.average_views = average_views[article.id]
        article.save
      end
    end
  end
end
