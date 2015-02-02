class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article



  ####################
  # Instance methods #
  ####################
  def update(data={}, save=true)
    self.attributes = data

    if save
      self.save
    end
  end



  #################
  # Class methods #
  #################
  def self.update_all_revisions
    results = []
    Course.all.each do |c|
      start = c.revisions.count == 0 ? c.start : c.revisions.order("date DESC").first.date
      start = start.strftime("%Y%m%d")
      revisions = Utils.chunk_requests(c.users.student, 40) do |block|
        Replica.get_revisions_this_term_by_users block, start, c.end.strftime("%Y%m%d")
      end
      results += revisions
    end

    self.import_revisions(results)

    ActiveRecord::Base.transaction do
      Revision.joins(:article).where(articles: {namespace: "0"}).each do |r|
        r.user.courses.each do |c|
          if((!c.articles.include? r.article) && (c.start <= r.date))
            c.articles << r.article
          end
        end
      end
    end
  end

  def self.import_revisions(data)
    articles = []
    revisions = []

    data.each do |a_id, a|
      if a.nil? || a["article"].nil?
        byebug
      end
      article = Article.new(id: a["article"]["id"])
      article.update(a["article"], false)
      articles.push article

      a["revisions"].each do |r|
        revision = Revision.new(id: r["id"])
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