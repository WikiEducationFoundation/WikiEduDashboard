class CoursesUsers < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  ####################
  # Instance methods #
  ####################
  def character_sum_ms
    if(!read_attribute(:character_sum_ms))
      update_cache()
    end
    read_attribute(:character_sum_ms)
  end

  def character_sum_us
    if(!read_attribute(:character_sum_us))
      update_cache()
    end
    read_attribute(:character_sum_us)
  end

  def revision_count
    if(!read_attribute(:revision_count))
      update_cache()
    end
    read_attribute(:revision_count)
  end

  def update_cache
    self.character_sum_ms = Revision.joins(:article).where(articles: {namespace: 0}).where(user_id: user.id).where('characters >= 0').where("date >= ?", course.start).sum(:characters) || 0
    self.character_sum_us = Revision.joins(:article).where(articles: {namespace: 2}).where(user_id: user.id).where('characters >= 0').where("date >= ?", course.start).sum(:characters) || 0
    self.revision_count = Revision.joins(:article).where(user_id: user.id).where("date >= ?", course.start).count || 0
    self.save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    CoursesUsers.all.each do |cu|
      cu.update_cache
    end
  end
end
