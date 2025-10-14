# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_pageviews"

class AverageViewsImporter
  DAYS_UNTIL_OUTDATED = 14
  def self.update_outdated_average_views(course)
    articles_courses_ids = course.articles_courses.pluck(:id)

    ArticlesCourses.where(id: articles_courses_ids)
                   .where(average_views_updated_at: nil)
                   .includes(article: :wiki).find_in_batches(batch_size: 200) do |article_group|
      update_average_views(article_group)
    end

    ArticlesCourses.where(id: articles_courses_ids)
                   .where('average_views_updated_at < ?', DAYS_UNTIL_OUTDATED.days.ago)
                   .includes(article: :wiki).find_in_batches(batch_size: 200) do |article_group|
      update_average_views(article_group)
    end
  end

  # We get some 429 / too many requests errors with 8
  MAX_HTTP_CONCURRENCY = 3
  def self.update_average_views(articles_courses)
    pool = Concurrent::FixedThreadPool.new(MAX_HTTP_CONCURRENCY)
    average_views = Concurrent::Hash.new
    time = Time.zone.today

    # Get the average views data and put it into a concurrency-safe datastructure
    articles_courses.each do |article_course|
      next if article_course.first_revision.nil?
      pool.post { update_average_views_for_article(article_course, average_views, time) }
    end

    pool.shutdown && pool.wait_for_termination # Block here until pool is done.

    # Now, take all the average views and save them to the DB in one fell swoop!
    ArticlesCourses.update(average_views.keys, average_views.values)
  end

  def self.update_average_views_for_article(article_course, average_views, time)
    views_since_revision = WikiPageviews.new(article_course.article)
                                        .average_views_from_date(article_course.first_revision)

    # Only update if there are views
    return unless views_since_revision.positive?

    average_views[article_course.id] = {
      average_views: views_since_revision,
      average_views_updated_at: time
    }
  end
end
