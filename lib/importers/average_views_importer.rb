# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_pageviews"

class AverageViewsImporter
  DAYS_UNTIL_OUTDATED = 14
  def self.update_outdated_average_views(articles)
    batch_size = 200
    last_id = nil # Track the last processed article ID to ensure continuous batch processing

    loop do
      # Build a query to fetch outdated articles in batches
      query = articles
              .where(average_views_updated_at: nil)
              .or(articles.where('average_views_updated_at < ?', DAYS_UNTIL_OUTDATED.days.ago))
              .includes(:wiki)
              .limit(batch_size)

      # Ensure we only fetch articles with IDs greater than the last processed one
      query = query.where('articles.id > ?', last_id) if last_id

      article_group = query.to_a # Convert the query result into an array for processing
      break if article_group.empty? # Exit loop if no more outdated articles exist

       # Update the average views for the batch of articles
      update_average_views(article_group)

      # Set last_id to the last processed article's ID to continue from there
      last_id = article_group.last.id.to_i
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
