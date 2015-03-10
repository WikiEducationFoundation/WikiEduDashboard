#= Article model
class Article < ActiveRecord::Base
  has_many :revisions
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { uniq }, through: :articles_courses
  has_many :assignments

  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(' ', '_')
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
    "https://en.wikipedia.org/wiki/#{ns[namespace]}#{escaped_title}"
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
      nv = Grok.views_for_article(title, since)
      nv = views unless views.nil?

      last = since
      ActiveRecord::Base.transaction do
        revisions.each do |r|
          r.views = all_time ? 0 : r.views
          r.views += new_views.reduce(0) do |sum, (d, v)|
            sum + d.to_date >= r.date ? v : 0
          end
          r.save
        end
        last = nv.sort_by { |(d)| d }.last.first.to_date unless nv.empty?
      end

      if revisions.order('date ASC').first.views - views > 0
        revision_views = revisions.order('date ASC').first.views - views
        puts I18n.t('article.views_added', count: revision_views, title: title)
      end

      self.views_updated_at = last.nil? ? views_updated_at : last
    end

    if revisions.count > 0
      self.views = revisions.order('date ASC').first.views
    else
      self.views = 0
    end
    save
  end

  #################
  # Cache methods #
  #################
  def character_sum
    update_cache unless read_attribute(:character_sum)
    read_attribute(:character_sum)
  end

  def revision_count
    read_attribute(:revision_count) || revisions.size
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
    articles = Article.where(namespace: 0).find_in_batches(batch_size: 30)
    update_views(articles, all_time)
  end

  def self.update_new_views
    articles = Article.where('views_updated_at IS NULL').where(namespace: 0)
               .find_in_batches(batch_size: 30)
    update_views(articles, true)
  end

  def self.update_all_caches
    Article.transaction do
      Article.all.each(&:update_cache)
    end
  end

  class << self
    private

    def self.update_views(articles, all_time=false)
      require './lib/grok'
      views, vua = {}
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
        views, vua = {}
      end
    end

    def self.update_ratings(articles)
      ratings = []
      Article.find_in_batches(batch_size: 20).with_index do |group, _batch|
        ratings += Wiki.get_article_rating(group.map(&:title))
      end
      # Do something with the ratings
    end
  end
end
