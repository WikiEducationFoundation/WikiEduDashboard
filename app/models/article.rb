require "#{Rails.root}/lib/utils"
require "#{Rails.root}/lib/importers/article_importer"

#= Article model
class Article < ActiveRecord::Base
  has_many :revisions
  has_many :editors, through: :revisions, source: :user
  has_many :articles_courses, class_name: ArticlesCourses
  has_many :courses, -> { uniq }, through: :articles_courses
  has_many :assignments

  scope :live, -> { where(deleted: false) }
  scope :current, -> { joins(:courses).merge(Course.current).uniq }
  scope :namespace, -> ns { where(namespace: ns) }

  ####################
  # Instance methods #
  ####################
  def url
    escaped_title = title.gsub(' ', '_')
    language = Figaro.env.wiki_language
    ns = {
      0 => '', # Mainspace for Wikipedia articles
      1 => 'Talk:',
      2 => 'User:',
      3 => 'User_talk:',
      4 => 'Wikipedia:',
      5 => 'Wikipedia_talk:',
      10 => 'Template:',
      11 => 'Template_talk:',
      118 => 'Draft:',
      119 => 'Draft_talk:'
    }
    prefix = ns[namespace]

    "https://#{language}.wikipedia.org/wiki/#{prefix}#{escaped_title}"
  end

  def update(data={}, save=true)
    self.attributes = data
    if revisions.count > 0
      self.views = revisions.order('date ASC').first.views || 0
    else
      self.views = 0
    end
    self.save if save
  end

  def update_views(all_time=false, views=nil)
    return unless views_updated_at < Date.today

    since = views_updated_at + 1.day
    since = courses.order(:start).first.start.to_date if all_time

    # Update views on all revisions and the article
    nv = views || ArticleImporter.views_for_article(title, since)

    last = since
    ActiveRecord::Base.transaction do
      revisions.each do |r|
        r.views = all_time ? 0 : r.views
        r.views += nv.reduce(0) do |sum, (d, v)|
          sum + (d.to_date >= r.date ? v : 0)
        end
        r.save
      end
      last = nv.sort_by { |(d)| d }.last.first.to_date unless nv.empty?
    end

    self.views_updated_at = last.nil? ? views_updated_at : last
    self.views = revisions.order('date ASC').first.views
    save
  end

  #################
  # Cache methods #
  #################
  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def revision_count
    self[:revision_count] || revisions.size
  end

  def update_cache
    # Do not consider revisions with negative byte changes
    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.revision_count = revisions.size
    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles=nil)
    Utils.run_on_all(Article, :update_cache, articles)
  end
end
