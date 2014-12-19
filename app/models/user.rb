class User < ActiveRecord::Base
  has_and_belongs_to_many :courses
  # has_many :assignments
  has_many :revisions
  has_many :articles, -> { uniq }, through: :revisions

  # Instance methods
  def contribution_url
    "https://en.wikipedia.org/wiki/Special:Contributions/#{self.wiki_id}"
  end

  def character_sum
    read_attribute(:character_sum) || revisions.sum(:characters)
  end

  def view_sum
    read_attribute(:view_sum) || articles.sum(:views)
  end

  def update_cache
    self.character_sum = revisions.sum(:characters)
    self.view_sum = articles.sum(:views)
    self.save
  end


  # Class methods
  def self.update_all_caches
    User.all.each do |u|
      u.update_cache
    end
  end
end

# Roles:
#   Instructors
#   Advisors
#   Student