# frozen_string_literal: true
require "#{Rails.root}/lib/word_count"

#= Presenter for users view
class UsersPresenter
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
    individual_courses.each do |c|
      individual_articles = c.articles
      individual_articles.each do |a|
        earliest_revision = a.revisions.where(user_id: @user.id).order('date ASC').first
        article_views += earliest_revision.views if earliest_revision.present?
      end
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
