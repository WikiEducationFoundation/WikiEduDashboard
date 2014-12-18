class Article < ActiveRecord::Base
  has_many :revisions

    # Instance methods
  def update_views

  end

  def update(data={})
    if data.blank?
      # Implement method for single-article lookup
    end

    self.title = data["page_title"]
    self.save
  end

  # Class methods
  def self.update_all_articles
    articles = Utils.chunk_requests(User.all) { |block|
      Replica.get_articles_edited_this_term_by_users block
    }
    articles.each do |a|
      article = Article.find_or_create_by(id: a["page_id"])
      article.update a
    end
  end
end