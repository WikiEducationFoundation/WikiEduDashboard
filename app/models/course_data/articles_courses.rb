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

  serialize :user_ids, Array # This text field only stores user ids as text

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
    course.revisions.live.where(article_id:)
  end

  def all_revisions
    course.all_revisions.where(article_id:)
  end

  def article_revisions
    article.revisions.where('date >= ?', course.start).where('date <= ?', course.end)
  end

  def update_cache
    revisions = live_manual_revisions.load

    self.character_sum = revisions.sum { |r| r.characters.to_i.positive? ? r.characters : 0 }
    self.references_count = revisions.sum(&:references_added)
    self.view_count = views_since_earliest_revision(revisions)
    self.user_ids = associated_user_ids(revisions)

    # We use the 'all_revisions' scope so that the dashboard system edits that
    # create sandboxes are not excluded, since those are often wind up being the
    # first edit of a mainspace article's revision history
    self.new_article = new_article || # If it's already known to be new, that won't change
                       all_revisions.exists?(new_article: true) || # First edit was by a student
                       # First edit was done automatically by the Dashboard during the course
                       article_revisions.exists?(new_article: true, system: true)
    save
  end

  def views_since_earliest_revision(revisions)
    return if revisions.blank?
    return if article.average_views.nil?
    days = (Time.now.utc.to_date - revisions.min_by(&:date).date.to_date).to_i
    days * article.average_views
  end

  def associated_user_ids(revisions)
    return [] if revisions.blank?
    revisions.filter_map(&:user_id).uniq
  end

  #################
  # Class methods #
  #################
  def self.update_all_caches(articles_courses)
    articles_courses.find_each(&:update_cache)
  end

  def self.update_from_course(course)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = get_revisions_by_namespaces(course).distinct.pluck(:article_id)

    # Remove all the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
    valid_article_ids = revision_article_ids & course_article_ids
    destroy_invalid_records(course, valid_article_ids)

    # Add new ArticlesCourses
    # Using `insert_all` is massively more efficient than inserting them one at a time.
    article_ids_without_ac = revision_article_ids - course_article_ids
    tracked_wiki_ids = course.wikis.pluck(:id)
    new_article_ids = Article.where(id: article_ids_without_ac, wiki_id: tracked_wiki_ids)
                             .pluck(:id)
    new_records = new_article_ids.map do |id|
      { article_id: id, course_id: course.id }
    end
    insert_all new_records unless new_records.empty?
  end

  def self.destroy_invalid_records(course, valid_article_ids)
    course_ac_records = course.articles_courses.pluck(:id, :article_id)
    course_ac_records.each do |(id, article_id)|
      next if valid_article_ids.include?(article_id)
      find(id).destroy
    end
  end

  def self.get_revisions_by_namespaces(course)
    # Select all mainspace article revisions
    revisions = course.revisions.joins(:article).where(articles: { namespace: 0 })
    # In addition, select revisions with tracked namespaces
    course.course_wiki_namespaces.each do |course_wiki_ns|
      next if course_wiki_ns.namespace == 0
      wiki = course_wiki_ns.courses_wikis.wiki
      revisions << revisions.joins(:article).where(articles: { wiki: wiki, namespace: course_wiki_ns.namespace })
    end
    revisions
  end
end
