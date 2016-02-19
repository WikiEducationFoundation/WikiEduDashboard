require "#{Rails.root}/lib/importers/article_importer"

class AssignedArticleImporter
  ################
  # Entry points #
  ################

  def self.import_articles_for_assignments
    assignments_missing_articles = Assignment.where(article_id: nil)
    assignments_missing_articles.group_by(&:wiki).each do |wiki, assignments|
      missing_titles = assignments.map(&:article_title).uniq
      ArticleImporter.new(wiki).import_articles_by_title(missing_titles)
      # FIXME: How are these "new"?
      new_article_titles = Article.where(namespace: 0, title: missing_titles, wiki_id: wiki.id).pluck(:title)
      Assignment.where(article_title: new_article_titles, wiki_id: wiki.id).each do |assignment|
        article = Article.find_by(title: assignment.article_title, wiki_id: wiki.id)
        next unless article.title == assignment.article_title # guard against case variants
        assignment.article_id = article.id
        assignment.save
      end
    end
  end
end
