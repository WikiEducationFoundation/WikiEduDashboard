class CoursesUsers < ActiveRecord::Base
  belongs_to :course
  belongs_to :user

  ####################
  # Instance methods #
  ####################
  def character_sum
    if(!read_attribute(:character_sum))
      update_cache()
    end
    read_attribute(:character_sum)
  end

  def update_cache
    self.character_sum = Revision.joins(:article).where(articles: {namespace: 0}).where(user_id: user.id).where('characters >= 0').where("date >= ?", course.start).sum(:characters) || 0
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
