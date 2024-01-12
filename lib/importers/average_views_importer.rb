# frozen_string_literal: true

require_dependency Rails.root.join('lib/wiki_pageviews')

class AverageViewsImporter
  DAYS_UNTIL_OUTDATED = 14
  def self.update_outdated_average_views(articles)
    articles.where(average_views_updated_at: nil).or(
      articles.where('average_views_updated_at < ?', DAYS_UNTIL_OUTDATED.days.ago)
    ).includes(:wiki).find_in_batches(batch_size: 200) do |article_group|
      update_average_views(article_group)
    end
  end

  # We get some 429 / too many requests errors with 8
  MAX_HTTP_CONCURRENCY = 3
  def self.update_average_views(articles)
    pool = Concurrent::FixedThreadPool.new(MAX_HTTP_CONCURRENCY)
    average_views = Concurrent::Hash.new
    time = Time.zone.today

    # Get the average views data and put it into a concurrency-safe datastructure
    articles.each do |article|
      pool.post { update_average_views_for_article(article, average_views, time) }
    end

    pool.shutdown && pool.wait_for_termination # Block here until pool is done.

    # Now, take all the average views and save them to the DB in one fell swoop!
    Article.update(average_views.keys, average_views.values)
  end

  def self.update_average_views_for_article(article, average_views, time)
    average_views[article.id] = {
      average_views: WikiPageviews.new(article).average_views,
      average_views_updated_at: time
    }
  end
end
