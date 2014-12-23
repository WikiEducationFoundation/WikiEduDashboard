class Article < ActiveRecord::Base
  has_many :revisions

  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(" ", "_")
    "https://en.wikipedia.org/wiki/#{escaped_title}"
  end

  def update_views

  end

  def update(data={})
    if data.blank?
      # Implement method for single-article lookup
    end

    puts "Updating #{title}"

    self.title = data["page_title"].gsub("_", " ")
    if(views_updated_at.nil? || views_updated_at < Date.today)
      self.views = Grok.get_all_views_for_article(data["page_title"], Date.today)
      self.views_updated_at = Date.today
    end
    self.save
  end

  # Cache methods
  def character_sum
    read_attribute(:character_sum) || self.revisions.sum(:characters)
  end

  def revision_count
    revisions.size
  end

  def update_cache
    self.character_sum = self.revisions.sum(:characters)
    self.save
  end

  #################
  # Class methods #
  #################
  def self.update_all_articles
    articles = Utils.chunk_requests(User.all) { |block|
      Replica.get_articles_edited_this_term_by_users block
    }
    articles.each do |a|
      article = Article.find_or_create_by(id: a["page_id"])
      article.update a
    end
  end

  def self.update_all_caches
    Article.all.each do |a|
      a.update_cache
    end
  end
end