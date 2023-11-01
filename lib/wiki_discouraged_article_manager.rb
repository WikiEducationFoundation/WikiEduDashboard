# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/category_importer"

class WikiDiscouragedArticleManager
  def retrieve_wiki_edu_discouraged_articles
    category_titles = [ENV['blocked_assignment_category'],
                       ENV['warning_assignment_category']]

    category_titles.each do |category_title|
      discouraged_articles = CategoryImporter.new(Wiki.default_wiki)
                                             .page_titles_for_category(category_title)
      update_or_save_discouraged_articles(discouraged_articles, category_title)
    end
  end

  private

  def update_or_save_discouraged_articles(discouraged_articles, category_title)
    existing_article = Category.find_by(source: category_title)

    if existing_article
      # Update the existing article
      existing_article.update(article_titles: discouraged_articles)
    else
      # Create a new entry in the database
      article_details = {
        article_titles: discouraged_articles,
        name: 'Wiki_Edu_Discouraged_Articles',
        source: category_title,
        wiki_id: en_wiki.id
      }
      Category.create(article_details)
    end
  end

  def en_wiki
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end
end
