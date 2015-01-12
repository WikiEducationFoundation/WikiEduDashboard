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

  def update_cache
    revisions = article.revisions.where("date >= ?", course.start)
    if revisions.empty?
      self.view_count = 0
      self.character_sum = 0
    else
      self.view_count = revisions.order('date ASC').first.views || 0
      self.character_sum = revisions.where('characters >= 0').sum(:characters) || 0
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
