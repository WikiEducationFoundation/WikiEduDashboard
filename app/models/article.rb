class Article < ActiveRecord::Base
  has_many :revisions
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { uniq }, through: :articles_courses
  has_many :assignments



  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(" ", "_")
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

    return 'https://en.wikipedia.org/wiki/' + ns[namespace] + escaped_title
  end


  def update(data={}, save=true)
    self.attributes = data

    if(self.revisions.count > 0)
      self.views = self.revisions.order('date ASC').first.views || 0
    else
      self.views = 0
    end

    if save
      self.save
    end
  end


  def update_views(all_time=false, views=nil)
    if(self.views_updated_at < Date.today)
      since = all_time ? self.courses.order(:start).first.start.to_date : self.views_updated_at + 1.day

      # Update views on all revisions and the article
      new_views = views.nil? ? Grok.get_views_since_date_for_article(self.title, since) : views
      last = since
      ActiveRecord::Base.transaction do
        self.revisions.each do |r|
          r.views = all_time ? 0 : r.views
          r.views += new_views.reduce(0) do |sum, (d, v)|
            sum += d.to_date >= r.date ? v : 0
          end
          r.save
        end
        last = new_views.empty? ? nil : new_views.sort_by { |(d)| d }.last.first.to_date
      end
      if(self.revisions.order('date ASC').first.views - self.views > 0)
        puts I18n.t("article.views_added", count: self.revisions.order('date ASC').first.views - self.views, title: self.title)
      end
      self.views_updated_at = last.nil? ? self.views_updated_at : last
    end

    if(self.revisions.count > 0)
      self.views = self.revisions.order('date ASC').first.views
    else
      self.views = 0
    end
    self.save
  end



  #################
  # Cache methods #
  #################
  def character_sum
    if(!read_attribute(:character_sum))
      update_cache()
    end
    read_attribute(:character_sum)
  end


  def revision_count
    read_attribute(:revision_count) || revisions.size
  end


  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.revision_count = revisions.size
    self.save
  end



  #################
  # Class methods #
  #################
  def self.update_all_views(all_time=false)
    articles = Article.where(namespace: 0).find_in_batches(batch_size: 30)
    self.update_views(articles, all_time)
  end


  def self.update_new_views
    articles = Article.where("views_updated_at IS NULL").where(namespace: 0).find_in_batches(batch_size: 30)
    self.update_views(articles, true)
  end


  def self.update_all_caches
    Article.transaction do
      Article.all.each do |a|
        a.update_cache
      end
    end
  end


  private
  def self.update_views(articles, all_time=false)
    require "./lib/grok"
    views = {}
    vua = {}
    articles.with_index do |group, batch|
      threads = group.each_with_index.map do |a, i|
        start = a.courses.order(:start).first.start.to_date
        Thread.new(i) do |j|
          vua[a.id] = a.views_updated_at || start
          if(vua[a.id] < Date.today)
            since = all_time ? start : vua[a.id] + 1.day
            views[a.id] = Grok.get_views_since_date_for_article(a.title, since)
          end
        end
      end
      threads.each { |t| t.join }
      group.each do |a|
        a.views_updated_at = vua[a.id]
        a.update_views(all_time, views[a.id])
      end
      views = {}
      vua = {}
    end
  end

  def self.update_ratings(articles)
    ratings = []
    Article.find_in_batches(batch_size: 20).with_index do |group, batch|
      ratings = ratings + Wiki.get_article_rating(group.map {|a| a.title})
    end
    # Do something with the ratings
  end


end
