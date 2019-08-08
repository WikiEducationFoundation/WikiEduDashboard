# frozen_string_literal: true

class RefreshCategoriesWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    Category.refresh_categories_for(Course.current)
  end
end
