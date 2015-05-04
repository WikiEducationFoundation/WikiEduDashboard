require "#{Rails.root}/lib/grok"
require "#{Rails.root}/lib/replica"
require "#{Rails.root}/lib/wiki"

#= Imports and updates articles from Wikipedia into the dashboard database
class ArticleImporter
  ################
  # Entry points #
  ################
  def self.update_all_views(all_time=false)
    articles = Article.current
               .where(articles: { namespace: 0 })
               .find_in_batches(batch_size: 30)
    update_views(articles, all_time)
  end

  def self.update_new_views
    articles = Article.current
               .where(articles: { namespace: 0 })
               .where('views_updated_at IS NULL')
               .find_in_batches(batch_size: 30)
    update_views(articles, true)
  end

  def self.update_all_ratings
    articles = Article.current
               .namespace(0).find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.update_new_ratings
    articles = Article.current
               .where('rating_updated_at IS NULL').namespace(0)
               .find_in_batches(batch_size: 30)
    update_ratings(articles)
  end

  def self.views_for_article(title, since)
    Grok.views_for_article title, since
  end

  def self.remove_bad_articles_courses
    non_student_cus = CoursesUsers.where(role: [1, 2, 3, 4])
    non_student_cus.each do |nscu|
      # Check if the non-student user is also a student in the same course.
      next unless CoursesUsers.where(
        role: 0,
        course_id: nscu.course_id,
        user_id: nscu.user.id
      ).empty?

      user_articles = nscu.user.revisions
                      .where('date >= ?', nscu.course.start)
                      .where('date <= ?', nscu.course.end)
                      .pluck(:article_id)

      next if user_articles.empty?

      course_articles = nscu.course.articles.pluck(:id)
      possible_deletions = course_articles & user_articles

      to_delete = []
      possible_deletions.each do |pd|
        other_editors = Article.find(pd).editors - [nscu.user.id]
        course_editors = nscu.course.students & other_editors
        to_delete.push pd if other_editors.empty? || course_editors.empty?
      end

      # remove orphaned articles from the course
      nscu.course.articles.delete(Article.find(to_delete))
      Rails.logger.info(
        "Deleted #{to_delete.size} ArticlesCourses from #{nscu.course.title}"
      )
      # update course cache to account for removed articles
      nscu.course.update_cache unless to_delete.empty?
    end
  end

  ##############
  # API Access #
  ##############
  def self.update_views(articles, all_time=false)
    require './lib/grok'
    views, vua = {}, {}
    articles.with_index do |group, _batch|
      threads = group.each_with_index.map do |a, i|
        start = a.courses.order(:start).first.start.to_date
        Thread.new(i) do
          vua[a.id] = a.views_updated_at || start
          if vua[a.id] < Date.today
            since = all_time ? start : vua[a.id] + 1.day
            views[a.id] = self.views_for_article(a.title, since)
          end
        end
      end
      threads.each(&:join)
      group.each do |a|
        a.views_updated_at = vua[a.id]
        a.update_views(all_time, views[a.id])
      end
      views, vua = {}, {}
    end
  end

  def self.update_ratings(articles)
    articles.with_index do |group, _batch|
      ratings = Wiki.get_article_rating(group.map(&:title)).inject(&:merge)
      next if ratings.blank?
      if ratings.keys.length == 1
        ratings = { ratings.keys[0][0] => ratings.values[0] }
      end
      threads = group.each_with_index.map do |a, i|
        Thread.new(i) do
          a.rating = ratings[a.title]
          a.rating_updated_at = Time.now
        end
      end
      threads.each(&:join)
      group.each(&:save)
    end
  end

  def self.update_articles_deleted
    # TODO: Narrow this down even more. Current courses, maybe?
    articles = Article.where(namespace: 0, deleted: false)
    existing_titles = Utils.chunk_requests(articles) do |block|
      Replica.get_existing_articles block
    end
    existing_titles.map! { |t| t.gsub('_', ' ') }
    deleted_titles = articles.pluck(:title) - existing_titles
    articles.where(title: deleted_titles).update_all(deleted: true)
  end
end
