#= Article model
class Article < ActiveRecord::Base
  has_many :revisions
  has_many :editors, through: :revisions, source: :user
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { uniq }, through: :articles_courses
  has_many :assignments

  scope :live, -> { where(deleted: false) }
  scope :current, -> { joins(:courses).merge(Course.current).uniq }
  scope :namespace, -> ns { where(namespace: ns) }

  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(' ', '_')
    language = Figaro.env.wiki_language
    ns = {
      0 => '', # Mainspace for Wikipedia articles
      1 => 'Talk:',
      2 => 'User:',
      3 => 'User_talk:',
      4 => 'Wikipedia:',
      5 => 'Wikipedia_talk:',
      10 => 'Template:',
      11 => 'Template_talk:',
      118 => 'Draft:',
      119 => 'Draft_talk:'
    }
    prefix = ns[namespace]

    "https://#{language}.wikipedia.org/wiki/#{prefix}#{escaped_title}"
  end

  def update(data={}, save=true)
    self.attributes = data
    if revisions.count > 0
      self.views = revisions.order('date ASC').first.views || 0
    else
      self.views = 0
    end
    self.save if save
  end

  def update_views(all_time=false, views=nil)
    if views_updated_at < Date.today
      since = views_updated_at + 1.day
      since = courses.order(:start).first.start.to_date if all_time

      # Update views on all revisions and the article
      nv = views || Grok.views_for_article(title, since)

      last = since
      ActiveRecord::Base.transaction do
        revisions.each do |r|
          r.views = all_time ? 0 : r.views
          r.views += nv.reduce(0) do |sum, (d, v)|
            sum + (d.to_date >= r.date ? v : 0)
          end
          r.save
        end
        last = nv.sort_by { |(d)| d }.last.first.to_date unless nv.empty?
      end
      if (revisions.order('date ASC').first.views - self.views) > 0
        # view_count = revisions.order('date ASC').first.views - self.views
        # Rails.logger.debug I18n
        #   .t('article.views_added', count: view_count, title: title)
      end

      self.views_updated_at = last.nil? ? views_updated_at : last
    end

    self.views = revisions.order('date ASC').first.views
    save
  end

  #################
  # Cache methods #
  #################
  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def revision_count
    self[:revision_count] || revisions.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.revision_count = revisions.size
    save
  end

  #################
  # Class methods #
  #################
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

  def self.update_all_caches(articles=nil)
    articles = [articles] if articles.is_a? Article
    Article.transaction do
      (articles || Article.current).each(&:update_cache)
    end
  end

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
            views[a.id] = Grok.views_for_article(a.title, since)
          end
        end
      end
      threads.each(&:join)
      group.each do |a|
        a.views_updated_at = vua[a.id]
        a.update_views(all_time, views[a.id])
      end
      views, vua = {}, {}
    end
  end

  def self.update_all_ratings
    articles = Article.current
               .namespace(0).find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.update_new_ratings
    articles = Article.current
               .where('rating_updated_at IS NULL').namespace(0)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.update_ratings(articles)
    articles.with_index do |group, _batch|
      ratings = Wiki.get_article_rating(group.map(&:title)).inject(&:merge)
      if ratings.keys.length == 1
        ratings = { ratings.keys[0][0] => ratings.values[0] }
      end
      threads = group.each_with_index.map do |a, i|
        Thread.new(i) do
          a.rating = ratings[a.title]
          a.rating_updated_at = Time.now
        end
      end
      threads.each(&:join)
      group.each(&:save)
    end
  end

  def self.update_articles_deleted
    # TODO: Narrow this down even more. Current courses, maybe?
    articles = Article.where(namespace: 0, deleted: false)
    existing_titles = Utils.chunk_requests(articles) do |block|
      Replica.get_existing_articles block
    end
    existing_titles.map! { |t| t.gsub('_', ' ') }
    deleted_titles = articles.pluck(:title) - existing_titles
    articles.where(title: deleted_titles).update_all(deleted: true)
  end
end
