require "#{Rails.root}/lib/importers/article_importer"

class AssignedArticleImporter
  ################
  # Entry points #
  ################

  def self.import_articles_for_assignments
    titles = Assignment.where(article_id: nil).pluck(:article_title).uniq
    ArticleImporter.import_articles_by_title(titles)
    new_article_titles = Article.where(namespace: 0, title: titles).pluck(:title)
    Assignment.where(article_title: new_article_titles).each do |assignment|
      article = Article.find_by(title: assignment.article_title)
      next unless article.title == assignment.article_title # guard against case variants
      assignment.article_id = article.id
      assignment.save
    end
  end
end
