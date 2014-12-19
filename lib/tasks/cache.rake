namespace :cache do

  desc 'Update cached values on all models'

  task :update_caches => :environment do
    Rails.logger.info "Updating all cached values"
    Article.update_all_caches
    User.update_all_caches
    Course.update_all_caches
  end

end