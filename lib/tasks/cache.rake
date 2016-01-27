namespace :cache do
  desc 'Update cached values for all models'
  task update_caches: 'batch:setup_logger' do
    Rails.logger.debug 'Updating Article cache'
    Article.update_all_caches
    Rails.logger.debug 'Updating ArticlesCourses cache'
    ArticlesCourses.update_all_caches
    Rails.logger.debug 'Updating CoursesUsers cache'
    CoursesUsers.update_all_caches
    Rails.logger.debug 'Updating Course cache'
    Course.update_all_caches
    Rails.logger.debug 'Finished updating cached values'
  end

  namespace :warm do
    desc 'Warm homepage fragment cache'
    task :homepage do
      sh "curl http://#{ENV['dashboard_url']}"
    end
  end
end
