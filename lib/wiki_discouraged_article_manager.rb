# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/importers/category_importer"

class WikiDiscouragedArticleManager
  def retrieve_wiki_edu_discouraged_articles
    update_or_create_discouraged_articles
  end

  private

  def update_or_create_discouraged_articles
    blocked_assignment_category = ENV['blocked_assignment_category']

    return unless blocked_assignment_category

    Category.find_or_create_by(
      name: blocked_assignment_category,
      wiki_id: en_wiki.id,
      source: 'category',
      depth: 0
    ).refresh_titles
  end

  def en_wiki
    Wiki.find_by(language: 'en', project: 'wikipedia')
  end
end
