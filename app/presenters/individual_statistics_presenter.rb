# frozen_string_literal: true

require "#{Rails.root}/lib/word_count"

# Presenter to provide statistics about a user's individual contributions during
# courses in which the user was a student.
class IndividualStatisticsPresenter
  def initialize(user:)
    @user = user
  end

  def individual_courses
    @user.courses.where('courses_users.role = ?', CoursesUsers::Roles::STUDENT_ROLE)
  end

  def course_string_prefix
    Features.default_course_string_prefix
  end

  def individual_word_count
    WordCount.from_characters CoursesUsers.where(user_id: @user.id).sum(:character_sum_ms)
  end

  def individual_upload_count
    upload_count = 0
    individual_courses.each do |c|
      upload_count += c.uploads.where(user_id: @user.id).count
    end
    upload_count
  end

  def individual_upload_usage_count
    upload_usage_count = 0
    individual_courses.each do |c|
      upload_usage_count += c.uploads.where(user_id: @user.id).sum(:usage_count)
    end
    upload_usage_count
  end

  def individual_article_count
    article_ids = []
    individual_courses.each do |c|
      article_ids += c.all_revisions.where(user_id: @user.id).pluck(:article_id).uniq
    end
    article_ids.uniq.count
  end

  def individual_article_views
    article_views = 0
    # hash structure is used for getting earliest revision of unique articles in
    # multiple courses where user is a student.
    article_revisions = {}
    individual_courses.each do |c|
      c.articles.pluck(:id).uniq.each do |article_id|
        # find the earliest revision of the article in this course
        earliest_revision = c.revisions.where(user_id: @user.id, article_id: article_id).order('date ASC').first
        next if earliest_revision.nil?
        # Considering revisions for same articles in multiple courses by an individual,
        # check if the earliest revision for this article in this course is the
        # actual earliest revision made by the user.
        if article_revisions[article_id].nil? || article_revisions[article_id].date > earliest_revision.date
          article_revisions[article_id] = earliest_revision
        end
      end
    end
    # count the views of the earliest revision made to an artcile by an individual
    # irrespective of the courses it was edited in.
    article_revisions.each_value do |revision|
      article_views += revision.views
    end
    article_views
  end

  def individual_articles_created
    new_article_count = 0
    individual_courses.each do |c|
      new_article_count += c.all_revisions.where(user_id: @user.id).where(new_article: true).count
    end
    new_article_count
  end
end
