namespace :user do

  desc 'Update the training data for all users'

  # Update user trained status
  task :update_users => :environment do
    Rails.logger.info "Updating all users training data"
    User.update_trained_users
  end

end