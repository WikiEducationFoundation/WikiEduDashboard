#= Article + Course join model
class ArticlesCourses < ActiveRecord::Base
  belongs_to :article
  belongs_to :course

  ####################
  # Instance methods #
  ####################
  def view_count
    update_cache unless self[:view_count]
    self[:view_count]
  end

  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def new_article
    self[:new_article]
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
  
  def self.update_from_revisions
    ActiveRecord::Base.transaction do
      Revision.joins(:article).where(articles: { namespace: '0' }).each do |r|
        r.user.courses.each do |c|
          if (!c.articles.include? r.article) && (c.start <= r.date)
            c.articles << r.article
          end
        end
      end
    end
  end
  
end
