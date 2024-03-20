# frozen_string_literal: true
require "#{Rails.root}/lib/default_campaign_update.rb"

class DefaultCampaignUpdateWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    return unless Features.wiki_ed?
    DefaultCampaignUpdate.new
  end
end
