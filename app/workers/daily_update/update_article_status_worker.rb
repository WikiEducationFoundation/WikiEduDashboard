# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_status_manager"

class UpdateArticleStatusWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    ArticleStatusManager.update_article_status
  end
end
