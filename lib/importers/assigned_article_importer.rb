# frozen_string_literal: true

require "#{Rails.root}/lib/importers/article_importer"

class AssignedArticleImporter
  def initialize(wiki)
    @wiki = wiki
  end
  ###############
  # Entry point #
  ###############

  def self.import_articles_for_assignments
    assignments_missing_articles = Assignment.where(article_id: nil)
    assignments_missing_articles.group_by(&:wiki).each do |wiki, assignments|
      new(wiki).import_articles(assignments)
    end
  end

  #########################
  # Wiki-specific routine #
  #########################
  def import_articles(assignments)
    missing_titles = assignments.map(&:article_title).uniq
    ArticleImporter.new(@wiki).import_articles_by_title(missing_titles)
    newly_imported_article_titles = Article.where(namespace: Article::Namespaces::MAINSPACE,
                                                  title: missing_titles,
                                                  wiki_id: @wiki.id).pluck(:title)
    assignments_to_update = Assignment.where(article_title: newly_imported_article_titles,
                                             wiki_id: @wiki.id)
    assignments_to_update.each do |assignment|
      update_assignment(assignment)
    end
  end

  def update_assignment(assignment)
    article = Article.find_by(title: assignment.article_title,
                              namespace: Article::Namespaces::MAINSPACE,
                              wiki_id: @wiki.id)
    return unless article.title == assignment.article_title # guard against case variants
    assignment.article_id = article.id
    assignment.save
  end
end
