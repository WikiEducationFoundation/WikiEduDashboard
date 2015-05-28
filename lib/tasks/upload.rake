require "#{Rails.root}/lib/importers/upload_importer"

namespace :upload do
  desc 'Import and update uploads for all users'
  task import_all_uploads: 'batch:setup_logger' do
    Rails.logger.debug 'Updating Commons uploads'
    UploadImporter.import_all_uploads(User.all)
  end

  desc 'Update global usage for all uploads'
  task update_usage_count: 'batch:setup_logger' do
    Rails.logger.debug 'Updating Commons uploads'
    UploadImporter.import_all_uploads(CommonsUpload.all)
  end
end
