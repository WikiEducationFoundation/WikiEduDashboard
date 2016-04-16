require "#{Rails.root}/lib/importers/user_importer"

namespace :user do
  desc 'Update the training data for all users'
  task update_users: 'batch:setup_logger' do
    Rails.logger.debug 'Updating user names, global ids, and training status'
    UserImporter.update_users
  end
end
