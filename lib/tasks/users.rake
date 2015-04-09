namespace :user do
  desc 'Update the training data for all users'
  task update_users: :environment do
    Rails.logger.info 'Updating user names, global ids, and training status'
    User.update_users
  end
end
