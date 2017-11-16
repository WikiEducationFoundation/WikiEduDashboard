# frozen_string_literal: true

require "#{Rails.root}/lib/wiki_pageviews"

#= Imports and updates views for articles, revisions, and join tables
class ViewImporter
  ################
  # Entry points #
  ################
  def self.update_all_views(all_time=false)
    articles = Article.current
                      .where(namespace: 0)
                      .includes(:wiki)
                      .find_in_batches(batch_size: 30)
    update_views(articles, all_time)
  end

  def self.update_new_views
    articles = Article.current
                      .where(namespace: 0)
                      .includes(:wiki)
                      .where('views_updated_at IS NULL')
                      .find_in_batches(batch_size: 30)
    update_views(articles, true)
  end

  ##############
  # API Access #
  ##############
  def self.update_views(articles, all_time=false)
    articles.with_index do |group, _batch|
      new(group, all_time)
    end
  end

  def initialize(articles, all_time)
    @articles = articles
    @all_time = all_time
    @views = {}
    @views_updated_at = {}
    update_views_for_articles_batch
    save_updated_views
  end

  private

  def update_views_for_articles_batch
    threads = @articles.each_with_index.map do |article, i|
      start = earliest_course_start_date(article)
      Thread.new(i) do
        fetch_views_in_thread(article, start)
      end
    end
    threads.each(&:join)
  end

  def fetch_views_in_thread(article, start)
    article_id = article.id
    @views_updated_at[article_id] = article.views_updated_at || start
    return unless @views_updated_at[article_id] < Time.zone.yesterday
    since = @all_time ? start : @views_updated_at[article_id] + 1.day
    @views[article_id] = WikiPageviews
                         .new(article).views_for_article(start_date: since,
                                                         end_date: Time.zone.yesterday)
  end

  ###########
  # Helpers #
  ###########
  def earliest_course_start_date(article)
    article.courses.order(:start).first.start.to_date
  end

  def save_updated_views
    @articles.each do |article|
      article.views_updated_at = @views_updated_at[article.id]
      update_views_for_article(article, @views[article.id])
    end
  end

  def update_views_for_article(article, views=nil)
    return if views.nil? # This will be the case if there are no views in the date range.
    return unless article.views_updated_at < Time.zone.yesterday

    add_views_to_revisions(article, views)
    update_views_updated_at(article, views)
  end

  def update_views_updated_at(article, views)
    since = views_since_when(article)
    last = views_last_updated(since, views)
    article.views_updated_at = last.nil? ? article.views_updated_at : last
    article.save
  end

  def views_since_when(article)
    since = if @all_time
              article.courses.order(:start).first.start.to_date
            else
              article.views_updated_at + 1.day
            end
    since
  end

  def views_last_updated(since, views)
    last = since
    last = views.sort_by { |(d)| d }.last.first.to_date unless views.empty?
    last
  end

  def add_views_to_revisions(article, views)
    ActiveRecord::Base.transaction do
      article.revisions.each do |rev|
        rev.views = @all_time ? 0 : rev.views
        rev.views += views.reduce(0) do |sum, (d, v)|
          sum + (d.to_date >= rev.date ? v : 0)
        end
        rev.save
      end
    end
  end
end
