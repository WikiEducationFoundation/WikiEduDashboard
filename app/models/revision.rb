#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  scope :after_date, -> (date) { where('date > ?', date) }

  ####################
  # Instance methods #
  ####################
  def update(data={}, save=true)
    self.attributes = data

    self.save if save
  end

  #################
  # Class methods #
  #################
  def self.update_all_revisions
    results = []
    Course.all.each do |c|
      start = c.start
      start = c.revisions.order('date DESC').first.date if c.revisions.count > 0
      start = start.strftime('%Y%m%d')
      revisions = Utils.chunk_requests(c.users.role('student'), 40) do |block|
        Replica.get_revisions block, start, c.end.strftime('%Y%m%d')
      end
      results += revisions
    end

    import_revisions(results)
    ArticlesCourses.update_from_revisions
  end

  def self.import_revisions(data)
    articles, revisions = [], []

    data.each do |_a_id, a|
      article = Article.new(id: a['article']['id'])
      article.update(a['article'], false)
      articles.push article

      a['revisions'].each do |r|
        revision = Revision.new(id: r['id'])
        revision.update(r, false)
        revisions.push revision
      end
    end

    Article.import articles
    Revision.import revisions

    ActiveRecord::Base.transaction do
      Assignment.where(article_id: nil).each do |a|
        article = Article.find_by(title: a.article_title)
        a.article_id = article.nil? ? nil : article.id
        a.save
      end
    end
  end
end
