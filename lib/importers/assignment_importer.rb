#= Keeps assignments updated to match moving articles
class AssignmentImporter
  # Update article ids for Assignments that lack them, if an Article with the
  # same title exists in mainspace.
  def self.update_assignment_article_ids
    ActiveRecord::Base.transaction do
      Assignment.where(article_id: nil).each do |assignment|
        title = assignment.article_title.tr(' ', '_')
        article = Article.where(namespace: 0, wiki_id: assignment.wiki_id).find_by(title: title)
        assignment.article_id = article.nil? ? nil : article.id
        assignment.save
      end
    end
  end

  def self.update_article_ids(raw_articles, wiki)
    articles = Article
               .where(title: raw_articles.map(&:title))
               .where(namespace: 0, wiki_id: wiki.id)
    Assignment.where(
      article_title: articles.pluck(:title),
      article_id: nil,
      wiki_id: wiki.id
    ).each do |assignment|
      article = articles.find_by(title: assignment.article_title)
      assignment.update(article_id: article.id)
    end
  end
end
