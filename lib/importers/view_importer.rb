require "#{Rails.root}/lib/wiki_pageviews"

#= Imports and updates views for articles, revisions, and join tables
class ViewImporter
  ################
  # Entry points #
  ################
  def self.update_all_views(all_time=false)
    articles = Article.current
               .where(articles: { namespace: 0 })
               .find_in_batches(batch_size: 30)
    update_views(articles, all_time)
  end

  def self.update_new_views
    articles = Article.current
               .where(articles: { namespace: 0 })
               .where('views_updated_at IS NULL')
               .find_in_batches(batch_size: 30)
    update_views(articles, true)
  end

  def self.update_average_views(articles)
    article_batches = articles.each_slice(30)
    article_batches.each do |batch|
      update_average_views_for_batch batch
    end
  end

  ##############
  # API Access #
  ##############
  def self.update_views(articles, all_time=false)
    articles.with_index do |group, _batch|
      update_views_for_batch(group, all_time)
    end
  end

  def self.update_views_for_batch(articles, all_time)
    views, vua = {}, {}
    threads = articles.each_with_index.map do |article, i|
      start = earliest_course_start_date(article)
      article_id = article.id
      Thread.new(i) do
        vua[article_id] = article.views_updated_at || start
        if vua[article_id] < Time.zone.yesterday
          since = all_time ? start : vua[article_id] + 1.day
          views[article_id] = WikiPageviews.views_for_article(article.title,
                                                              start_date: since,
                                                              end_date: Time.zone.yesterday)
        end
      end
    end
    threads.each(&:join)

    save_updated_views(articles, views, vua, all_time)
  end

  def self.update_average_views_for_batch(articles)
    average_views = {}
    threads = articles.each_with_index.map do |article, i|
      Thread.new(i) do
        average_views[article.id] = WikiPageviews.average_views_for_article(article.title)
      end
    end
    threads.each(&:join)

    datestamp = Time.zone.today
    save_updated_average_views(articles, average_views, datestamp)
  end

  ###########
  # Helpers #
  ###########
  def self.earliest_course_start_date(article)
    article.courses.order(:start).first.start.to_date
  end

  def self.save_updated_views(articles, views, views_updated_at, all_time)
    articles.each do |article|
      article.views_updated_at = views_updated_at[article.id]
      update_views_for_article(article, all_time, views[article.id])
    end
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

  def self.update_views_for_article(article, all_time=false, views=nil)
    return unless article.views_updated_at < Time.zone.yesterday

    since = views_since_when(article, all_time)

    # Update views on all revisions and the article
    views ||= WikiPageviews.views_for_article(article.title, start_date: since,
                                                             end_date: Time.zone.yesterday)
    return if views.nil? # This will be the case if there are no views in the date range.
    add_views_to_revisions(article, views, all_time)

    last = views_last_updated(since, views)
    article.views_updated_at = last.nil? ? article.views_updated_at : last
    if article.revisions.count > 0
      article.views = article.revisions.order('date ASC').first.views
    end
    article.save
  end

  def self.views_since_when(article, all_time)
    if all_time
      since = article.courses.order(:start).first.start.to_date
    else
      since = article.views_updated_at + 1.day
    end
    since
  end

  def self.views_last_updated(since, views)
    last = since
    last = views.sort_by { |(d)| d }.last.first.to_date unless views.empty?
    last
  end

  def self.add_views_to_revisions(article, views, all_time)
    ActiveRecord::Base.transaction do
      article.revisions.each do |rev|
        rev.views = all_time ? 0 : rev.views
        rev.views += views.reduce(0) do |sum, (d, v)|
          sum + (d.to_date >= rev.date ? v : 0)
        end
        rev.save
      end
    end
  end
end
