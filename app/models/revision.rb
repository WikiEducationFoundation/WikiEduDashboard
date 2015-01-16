class Revision < ActiveRecord::Base
  belongs_to :user, counter_cache: true
  belongs_to :article, counter_cache: true



  ####################
  # Instance methods #
  ####################
  def update(data={})
    self.attributes = data["revision"]
    self.user = User.find_by(wiki_id: data["extra"]["user_wiki_id"])
    self.article = Article.find_by(id: data["article"]["id"])
    self.save

    # Set up articles_courses join tables
    if(data["article"]["namespace"].to_i == 0)
      self.user.courses.each do |c|
        if((!c.articles.include? self.article) && (c.start <= self.date))
          c.articles << self.article
        end
      end
    else
    end
  end



  #################
  # Class methods #
  #################
  def self.update_all_revisions
    revisions = Utils.chunk_requests(User.student, 40) { |block|
      Replica.get_revisions_this_term_by_users block
    }
    revisions.each do |r|
      article = Article.find_or_create_by(id: r["article"]["id"])
      article.update r["article"]
      revision = Revision.find_or_create_by(id: r["revision"]["id"])
      revision.update r
    end
  end


end