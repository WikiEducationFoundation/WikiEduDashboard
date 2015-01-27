class Article < ActiveRecord::Base
  has_many :revisions
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { uniq }, through: :articles_courses



  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(" ", "_")
    if(namespace == 0)
      "https://en.wikipedia.org/wiki/#{escaped_title}"
    else
      "https://en.wikipedia.org/wiki/User:#{escaped_title}"
    end
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
    if(self.views_updated_at.nil?)
      self.views_updated_at = (self.courses.order(:start).first || CourseList).start.to_date
    end

    if(self.views_updated_at < Date.today)
      since = all_time ? ((self.courses.order(:start).first || CourseList).start.to_date) : self.views_updated_at + 1.day

      if all_time
        self.revisions.update_all(views: 0)
      end

      # Update views on all revisions and the article
      new_views = views.nil? ? Grok.get_views_since_date_for_article(self.title, since) : views
      last = since
      ActiveRecord::Base.transaction do
        new_views.each do |date, view_count|
          self.revisions.where("date <= ?", date).find_each do |r|
            r.views = r.views.nil? ? view_count : r.views + view_count
            r.save
          end
          last = date.to_date > last ? date.to_date : last
        end
      end
      if(self.revisions.order('date ASC').first.views - self.views > 0)
        puts "Added #{self.revisions.order('date ASC').first.views - self.views} new views for #{self.title}"
      end
      self.views_updated_at = last
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
    require "./lib/course_list"
    require "./lib/grok"
    articles = Article.where(namespace: 0).find_in_batches(batch_size: 50)
    articles.with_index do |group, batch|
      views = {}
      threads = group.each_with_index.map do |a, i|
        start = (a.courses.order(:start).first || CourseList).start.to_date
        Thread.new(i) do |i|
          views_updated_at = a.views_updated_at || start
          if(views_updated_at < Date.today)
            since = all_time ? start : views_updated_at + 1.day
            views[a.id] = Grok.get_views_since_date_for_article(a.title, since)
          end
        end
      end
      threads.each { |t| t.join }
      group.each do |a|
        a.update_views(all_time, views[a.id])
      end
    end
  end


  def self.update_new_views
    require "./lib/course_list"
    require "./lib/grok"
    articles = Article.where("views_updated_at IS NULL").where(namespace: 0).find_in_batches(batch_size: 60)
    articles.with_index do |group, batch|
      views = {}
      threads = group.each_with_index.map do |a, i|
        since = (a.courses.order(:start).first || CourseList).start.to_date
        Thread.new(i) do |i|
          if(since < Date.today)
            views[a.id] = Grok.get_views_since_date_for_article(a.title, since.to_date)
          end
        end
      end
      threads.each { |t| t.join }
      group.each do |a|
        a.update_views(true, views[a.id])
      end
    end
  end


  def self.update_all_caches
    Article.transaction do
      Article.all.each do |a|
        a.update_cache
      end
    end
  end


end