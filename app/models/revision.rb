class Revision < ActiveRecord::Base
  belongs_to :user, counter_cache: true
  belongs_to :article, counter_cache: true

  ####################
  # Instance methods #
  ####################
  def update(data={})
    if data.blank?
      # Implement method for single-revision lookup
    end

    self.date = data["rev_timestamp"].to_date
    self.characters = data["byte_change"]
    self.user = User.find_by(wiki_id: data["rev_user_text"])
    self.article = Article.find_by(id: data["page_id"])
    self.save

    # Set up articles_courses join tables
    self.user.courses.each do |c|
      if((!c.articles.include? self.article) && (c.start <= self.date))
        c.articles << self.article
      end
    end
  end

  #################
  # Class methods #
  #################
  def self.update_all_revisions
    revisions = Utils.chunk_requests(User.all, 100) { |block|
      Replica.get_revisions_this_term_by_users block
    }
    revisions.each do |r|
      if(r["byte_change"].to_i > 0)
        article = Article.find_or_create_by(id: r["page_id"])
        article.update r
        revision = Revision.find_or_create_by(id: r["rev_id"])
        revision.update r
      end
    end
  end
end
