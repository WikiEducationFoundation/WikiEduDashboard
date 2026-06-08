# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/user_importer"

class FetchUserRegistrationWorker
  include Sidekiq::Worker
  sidekiq_options lock: :until_executed

  def perform(user_id)
    user = User.find_by(id: user_id)
    return unless user
    UserImporter.update_users([user])
  end
end
