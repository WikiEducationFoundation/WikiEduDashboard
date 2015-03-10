#= Article + Course join model
class ArticlesCourses < ActiveRecord::Base
  belongs_to :article
  belongs_to :course

  ####################
  # Instance methods #
  ####################
  def view_count
    update_cache unless read_attribute(:view_count)
    read_attribute(:view_count)
  end

  def character_sum
    update_cache unless read_attribute(:character_sum)
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
      characters = revisions.where('characters >= 0').sum(:characters) || 0
      self.view_count = revisions.order('date ASC').first.views || 0
      self.character_sum = characters
      self.new_article = revisions.where(new_article: true).count > 0
    end
    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches
    ArticlesCourses.all.each(&:update_cache)
  end
end
