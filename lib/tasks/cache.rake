namespace :cache do

  desc 'Update cached values for all models'
  task :update_caches => :environment do
    Rails.logger.info "Updating Article cache"
    Article.update_all_caches
    Rails.logger.info "Updating User cache"
    User.update_all_caches
    Rails.logger.info "Updating ArticlesCourses cache"
    ArticlesCourses.update_all_caches
    Rails.logger.info "Updating CoursesUsers cache"
    CoursesUsers.update_all_caches
    Rails.logger.info "Updating Course cache"
    Course.update_all_caches
    Rails.logger.info "Finished updating cached values"
  end

end
