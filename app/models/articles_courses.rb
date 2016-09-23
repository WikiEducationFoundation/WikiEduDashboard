# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id            :integer          not null, primary key
#  created_at    :datetime
#  updated_at    :datetime
#  article_id    :integer
#  course_id     :integer
#  view_count    :integer          default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

require "#{Rails.root}/lib/utils"

#= ArticlesCourses is a join model between Article and Course.
#= It represents a mainspace Wikipedia article that has been worked on by a
#= student in a course.
class ArticlesCourses < ActiveRecord::Base
  belongs_to :article
  belongs_to :course

  scope :live, -> { joins(:article).where(articles: { deleted: false }).distinct }
  scope :new_article, -> { where(new_article: true) }
  scope :current, -> { joins(:course).merge(Course.current).distinct }

  ####################
  # Instance methods #
  ####################
  def view_count
    update_cache unless self[:view_count]
    self[:view_count]
  end

  def character_sum
    update_cache unless self[:character_sum]
    self[:character_sum]
  end

  def new_article
    self[:new_article]
  end

  def manual_revisions
    course.revisions.where(article_id: article.id)
  end

  def all_revisions
    course.all_revisions.where(article_id: article.id)
  end

  def update_cache
    revisions = manual_revisions

    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.view_count = revisions.order('date ASC').first.views unless revisions.empty?

    # We use the 'all_revisions' scope so that the dashboard system edits that
    # create sandboxes are not excluded, since those are often wind up being the
    # first edit of a mainspace article's revision history
    self.new_article = all_revisions.where(new_article: true).count.positive?

    save
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles_courses=nil)
    Utils.run_on_all(ArticlesCourses, :update_cache, articles_courses)
  end

  def self.update_from_course(course)
    mainspace_revisions = get_mainspace_revisions(course.revisions)
    course_article_ids = course.articles.pluck(:id)
    revision_article_ids = mainspace_revisions.pluck(:article_id).uniq

    # Remove all the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    course.articles_courses.where.not(article_id: revision_article_ids).destroy_all

    # Add new ArticlesCourses
    ActiveRecord::Base.transaction do
      revision_article_ids.each do |article_id|
        next if course_article_ids.include?(article_id)
        course.articles << Article.find(article_id)
      end
    end
  end

  def self.get_mainspace_revisions(revisions)
    revisions.joins(:article).where(articles: { namespace: '0' })
  end
end
