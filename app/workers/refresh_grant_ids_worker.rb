# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/grant_id_list"

# Copies the valid grant IDs from the grant ID spreadsheet
class RefreshGrantIdsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'default', retry: 0

  def perform
    return if Features.wiki_ed?
    return unless GrantIdList.configured?

    count = GrantIdList.refresh
    result = count ? "stored #{count}" : 'kept the previous'
    Rails.logger.info "RefreshGrantIdsWorker: #{result} grant IDs"
  end
end
