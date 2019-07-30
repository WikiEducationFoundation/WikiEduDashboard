# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/importers/upload_importer"

class UpdateCommonsUploadsWorker
  include Sidekiq::Worker
  sidekiq_options unique: :until_executed

  def perform
    UploadImporter.find_deleted_files
  end
end
