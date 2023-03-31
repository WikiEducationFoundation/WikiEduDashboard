# frozen_string_literal: true
class DeletedArticlesWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    DeletedArticlesUpdate.new
  end
end
