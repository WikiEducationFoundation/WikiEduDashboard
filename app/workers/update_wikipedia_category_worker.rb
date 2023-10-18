# frozen_string_literal: true

class UpdateWikipediaCategoryWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    # Logic for fetching and saving data
    WikipediaCategoryMember.new.fetch_category_members
  end
end
