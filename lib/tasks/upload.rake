require "#{Rails.root}/lib/importers/upload_importer"

namespace :upload do
  desc 'Import and update uploads for all users'
  task import_all_uploads: 'batch:setup_logger' do
    Rails.logger.debug 'Updating Commons uploads'
    UploadImporter.import_all_uploads(User.all)
  end

  desc 'Update global usage for all uploads'
  task update_usage_count: 'batch:setup_logger' do
    Rails.logger.debug 'Updating Commons uploads usage counts'
    UploadImporter.update_usage_count(CommonsUpload.where(deleted: false))
  end

  desc 'Find files that have been deleted'
  task find_deleted_files: 'batch:setup_logger' do
    Rails.logger.debug 'Identifying deleted Commons uploads'
    UploadImporter.find_deleted_files(CommonsUpload.where(deleted: false))
  end

  desc 'Get thumbnail urls for all uploads that lack them'
  task get_thumbnail_urls: 'batch:setup_logger' do
    Rails.logger.debug 'Getting thumbnail urls for Commons uploads'
    thumbless_uploads = CommonsUpload.where(thumburl: nil, deleted: false)
    UploadImporter.import_urls_in_batches(thumbless_uploads)
  end
end
