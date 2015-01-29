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
    data = Figaro.env.cohorts.split(",").reduce([]) do |result, cohort|
      users = User.student.includes(:courses).where(:courses => {:cohort => cohort})
      start = ENV["cohort_" + cohort + "_start"]
      unless Revision.all.count == 0
        start = Revision.all.order("date DESC").first.date.strftime("%Y%m%d")
      end
      revisions = Utils.chunk_requests(users, 40) { |block|
        cohort_start = start
        cohort_end = ENV["cohort_" + cohort + "_end"]
        Replica.get_revisions_this_term_by_users block, cohort_start, cohort_end
      }
      result += revisions
    end
    self.import_revisions(data)

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