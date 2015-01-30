class ArticlesCourses < ActiveRecord::Base
  belongs_to :article
  belongs_to :course

  ####################
  # Instance methods #
  ####################
  def view_count
    if(!read_attribute(:view_count))
      update_cache()
    end
    read_attribute(:view_count)
  end

  def character_sum
    if(!read_attribute(:character_sum))
      update_cache()
    end
    read_attribute(:character_sum)
  end

  def new_article
    read_attribute(:new_article)
  end

  def update_cache
    revisions = course.revisions.where(article_id: article.id)
    if revisions.empty?
      self.view_count = 0
      self.character_sum = 0
    else
      self.view_count = revisions.order('date ASC').first.views || 0
      self.character_sum = revisions.where('characters >= 0').sum(:characters) || 0
      self.new_article = revisions.where(new_article: true).count > 0
    end
    self.save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    ArticlesCourses.all.each do |ac|
      ac.update_cache
    end
  end
end
