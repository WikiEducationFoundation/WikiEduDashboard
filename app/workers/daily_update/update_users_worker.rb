# frozen_string_literal: true

require_dependency Rails.root.join('lib/importers/user_importer')

class UpdateUsersWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform
    UserImporter.update_users
  end
end
