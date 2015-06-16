require "#{Rails.root}/lib/grok"

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

  ##############
  # API Access #
  ##############
  def self.update_views(articles, all_time=false)
    articles.with_index do |group, _batch|
      update_views_for_batch(group, all_time)
    end
  end

  def self.update_views_for_batch(group, all_time)
    views, vua = {}, {}
    threads = group.each_with_index.map do |a, i|
      start = a.courses.order(:start).first.start.to_date
      Thread.new(i) do
        vua[a.id] = a.views_updated_at || start
        if vua[a.id] < Date.today
          since = all_time ? start : vua[a.id] + 1.day
          views[a.id] = Grok.views_for_article a.title, since
        end
      end
    end
    threads.each(&:join)
    group.each do |a|
      a.views_updated_at = vua[a.id]
      update_views_for_article(a, all_time, views[a.id])
    end
  end

  ###########
  # Helpers #
  ###########
  def self.update_views_for_article(article, all_time=false, views=nil)
    return unless article.views_updated_at < Date.today

    since = views_since_when(article, all_time)

    # Update views on all revisions and the article
    views ||= Grok.views_for_article(article.title, since)

    add_views_to_revisions(article, views, all_time)

    last = since
    last = views.sort_by { |(d)| d }.last.first.to_date unless views.empty?
    article.views_updated_at = last.nil? ? article.views_updated_at : last
    if article.revisions.count > 0
      article.views = article.revisions.order('date ASC').first.views
    end
    article.save
  end

  def self.views_since_when(article, all_time)
    since = article.views_updated_at + 1.day
    since = article.courses.order(:start).first.start.to_date if all_time
    since
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
