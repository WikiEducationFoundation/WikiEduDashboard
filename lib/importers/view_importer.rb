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
    require './lib/grok'
    views, vua = {}, {}
    articles.with_index do |group, _batch|
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
      views, vua = {}, {}
    end
  end

  ###########
  # Helpers #
  ###########
  def self.update_views_for_article(article, all_time=false, views=nil)
    require './lib/grok'
    return unless article.views_updated_at < Date.today

    since = article.views_updated_at + 1.day
    since = article.courses.order(:start).first.start.to_date if all_time

    # Update views on all revisions and the article
    nv = views || Grok.views_for_article(article.title, since)

    last = since
    ActiveRecord::Base.transaction do
      article.revisions.each do |r|
        r.views = all_time ? 0 : r.views
        r.views += nv.reduce(0) do |sum, (d, v)|
          sum + (d.to_date >= r.date ? v : 0)
        end
        r.save
      end
      last = nv.sort_by { |(d)| d }.last.first.to_date unless nv.empty?
    end

    article.views_updated_at = last.nil? ? article.views_updated_at : last
    article.views = article.revisions.order('date ASC').first.views
    article.save
  end
end
