# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/category_importer"

class WikiDiscouragedArticleManager
  def retrieve_wiki_edu_discouraged_articles
    update_or_create_discouraged_articles
  end

  private

  def update_or_create_discouraged_articles
    blocked_assignment_category = ENV['blocked_assignment_category']

    if blocked_assignment_category
      Category.find_or_create_by(
        name: blocked_assignment_category,
        wiki_id: en_wiki.id,
        source: 'category',
        depth: 0
      ).refresh_titles
    else
      Rails.logger.info 'blocked_assignment_category not set'
    end
  end

  def en_wiki
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end
end
