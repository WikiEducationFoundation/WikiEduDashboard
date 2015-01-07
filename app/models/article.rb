class Article < ActiveRecord::Base
  has_many :revisions

  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(" ", "_")
    "https://en.wikipedia.org/wiki/#{escaped_title}"
  end

  def update(data={})
    if data.blank?
      # Implement method for single-article lookup
    end

    puts "Updating #{title}"
    self.title = data["page_title"].gsub("_", " ")
    if(self.revisions.count > 0)
      self.views = self.revisions.order('date ASC').first.views
    else
      self.views = 0
    end
    self.save
  end

  def update_views(all_time)
    since = all_time ? CourseList.start.to_date : Date.today

    if all_time
      self.revisions.each do |r|
        r.views = 0
        r.save
      end
    end

    # Update views on all revisions and the article
    puts "Getting views for #{self.title} since #{since.strftime('%Y-%m-%d')}"
    new_views = Grok.get_views_since_date_for_article(self.title, since)
    new_views.each do |date, view_count|
      updated = all_time ? Time.now.utc + 1.day : since
      puts "#{date} - #{updated.strftime('%Y-%m-%d')} - #{view_count}"
      self.revisions.where("date <= ?", date).where("updated_at < ?", updated.strftime('%Y-%m-%d')).find_each do |r|
        r.views = r.views.nil? ? view_count : r.views + view_count
        r.save
      end
    end
    if(self.revisions.count > 0)
      self.views = self.revisions.order('date ASC').first.views
    else
      self.views = 0
    end
    self.save
  end

  # Cache methods
  def character_sum
    # Do not consider revisions with negative byte changes
    read_attribute(:character_sum) || revisions.where('characters > 0').sum(:characters)
  end

  def revision_count
    revisions.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters > 0').sum(:characters)
    self.save
  end

  #################
  # Class methods #
  #################

  # This is no longer used by the application
  def self.update_all_articles
    articles = Utils.chunk_requests(User.all) { |block|
      Replica.get_articles_edited_this_term_by_users block
    }
    articles.each do |a|
      article = Article.find_or_create_by(id: a["page_id"])
      article.update a
    end
  end

  def self.update_all_views(all_time=false)
    Article.all.each do |a|
      a.update_views(all_time)
    end
  end

  def self.update_all_caches
    Article.all.each do |a|
      a.update_cache
    end
  end

  # Variable descriptons
  def self.character_def
    "The gross sum of characters added to and removed from each article by the course's students during the course term"
  end

  def self.view_def
    "The sum of all views to each article during the course term"
  end
end