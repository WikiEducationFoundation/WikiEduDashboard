# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_discouraged_article_manager"

class WikiDiscouragedArticleWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    WikiDiscouragedArticleManager.new.retrieve_wiki_edu_discouraged_articles
  end
end
