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
#  view_count    :bigint(8)        default(0)
#  character_sum :integer          default(0)
#  new_article   :boolean          default(FALSE)
#

#= ArticlesCourses is a join model between Article and Course.
#= It represents a mainspace Wikipedia article that has been worked on by a
#= student in a course.
class ArticlesCourses < ApplicationRecord
  belongs_to :article
  belongs_to :course

  scope :live, -> { joins(:article).where(articles: { deleted: false }).distinct }
  scope :new_article, -> { where(new_article: true) }
  scope :current, -> { joins(:course).merge(Course.current).distinct }
  scope :ready_for_update, -> { joins(:course).merge(Course.ready_for_update).distinct }
  scope :tracked, -> { where(tracked: true).distinct }
  scope :not_tracked, -> { where(tracked: false).distinct }

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

  def references_count
    update_cache unless self[:references_count]
    self[:references_count]
  end

  def new_article
    self[:new_article]
  end

  def live_manual_revisions
    course.revisions.live.where(article_id: article_id)
  end

  def all_revisions
    course.all_revisions.where(article_id: article_id)
  end

  def update_cache
    revisions = live_manual_revisions

    self.character_sum = revisions.where('characters >= 0').sum(:characters)
    self.references_count = revisions.sum(&:references_added)
    self.view_count = views_since_earliest_revision(revisions)

    # We use the 'all_revisions' scope so that the dashboard system edits that
    # create sandboxes are not excluded, since those are often wind up being the
    # first edit of a mainspace article's revision history
    self.new_article = all_revisions.exists?(new_article: true)

    save
  end

  def views_since_earliest_revision(revisions)
    return if revisions.empty?
    return if article.average_views.nil?
    days = (Time.now.utc.to_date - revisions.order('date ASC').first.date.to_date).to_i
    days * article.average_views
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles_courses)
    articles_courses.find_each(&:update_cache)
  end

  def self.update_from_course(course)
    mainspace_revisions = get_mainspace_revisions(course.revisions)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = mainspace_revisions.pluck(:article_id).uniq

    # Remove all the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
    tracked_article_ids = revision_article_ids & course_article_ids
    course.articles_courses.where.not(article_id: tracked_article_ids).destroy_all

    # Add new ArticlesCourses
    ActiveRecord::Base.transaction do
      revision_article_ids.each do |article_id|
        next if course_article_ids.include?(article_id)
        article = Article.find(article_id)
        next unless course.wikis.include?(article.wiki)
        course.articles << article
      end
    end
  end

  def self.get_mainspace_revisions(revisions)
    revisions.joins(:article).where(articles: { namespace: '0' })
  end
end
