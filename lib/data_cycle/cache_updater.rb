class CacheUpdater
  def self.update_all_caches
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
end
