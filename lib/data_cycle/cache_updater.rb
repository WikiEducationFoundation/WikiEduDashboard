# frozen_string_literal: true

module CacheUpdater
  CACHE_UPDATE_CONCURRENCY = 5

  def update_all_caches
    log_message 'Updating ArticlesCourses cache'
    ArticlesCourses.update_all_caches
    log_message 'Updating CoursesUsers cache'
    CoursesUsers.update_all_caches_concurrently(CACHE_UPDATE_CONCURRENCY)
    log_message 'Updating Course cache'
    Course.update_all_caches_concurrently(CACHE_UPDATE_CONCURRENCY)
    log_message 'Finished updating cached values'
  end
end
