# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/assigned_article_importer')

class FindAssignmentsWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    AssignedArticleImporter.import_articles_for_assignments
  end
end
