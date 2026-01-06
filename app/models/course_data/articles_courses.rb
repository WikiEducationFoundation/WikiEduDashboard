# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id                       :integer          not null, primary key
#  created_at               :datetime
#  updated_at               :datetime
#  article_id               :integer
#  course_id                :integer
#  view_count               :bigint           default(0)
#  character_sum            :integer          default(0)
#  new_article              :boolean          default(FALSE)
#  references_count         :integer          default(0)
#  tracked                  :boolean          default(TRUE)
#  user_ids                 :text(65535)
#  first_revision           :datetime
#  average_views            :float(24)
#  average_views_updated_at :date
#

require_dependency "#{Rails.root}/lib/timeslice_manager"

#= ArticlesCourses is a join model between Article and Course.
#= It represents a mainspace Wikipedia article that has been worked on by a
#= student in a course.
class ArticlesCourses < ApplicationRecord
  belongs_to :article
  belongs_to :course

  has_many :article_course_timeslices, lambda { |articles_courses|
                                         where article: articles_courses.article
                                       }, through: :course

  scope :live, -> { joins(:article).where(articles: { deleted: false }).distinct }
  scope :new_article, -> { where(new_article: true) }
  scope :current, -> { joins(:course).merge(Course.current).distinct }
  scope :tracked, -> { where(tracked: true).distinct }
  scope :not_tracked, -> { where(tracked: false).distinct }

  serialize :user_ids, type: Array # This text field only stores user ids as text

  ####################
  # Instance methods #
  ####################
  def update_cache_from_timeslices
    self.character_sum = article_course_timeslices.sum(&:character_sum)
    self.references_count = article_course_timeslices.sum(&:references_count)
    self.user_ids = article_course_timeslices.sum([], &:user_ids).uniq
    self.new_article = article_course_timeslices.any?(&:new_article)
    self.first_revision = article_course_timeslices.minimum(:first_revision)
    save
  end

  #################
  # Class methods #
  #################

  # Search by course and user.
  def self.search_by_course_and_user(course, user_id)
    ArticlesCourses.where(course:).where('user_ids LIKE ?', "%- #{user_id}\n%")
  end

  # Calculate articles courses that need a cache update. For courses with a huge number
  # of articles, updating all caches in every update can be heavy. In order to
  # speed up the cache update process, we calculate the articles courses that
  # have at least one timeslice that was updated after the last course update,
  # and upate the cache only for them.
  # If no course update exists yet, then we update all the articles courses.
  def self.articles_courses_to_update(course)
    last_update = course.flags['update_logs'].values.last['end_time']
    Rails.logger.info "Updating partial ArticlesCourses caches for #{course.title}"
    course.article_course_timeslices.where('updated_at >= ?', last_update)
          .distinct
          .pluck(:article_id)
  rescue StandardError
    Rails.logger.info "Updating caches for all ArticlesCourses for #{course.title}"
    course.articles_courses.pluck(:article_id)
  end

  def self.update_required_caches_from_timeslices(course)
    ArticlesCourses.where(article_id: articles_courses_to_update(course))
                   .find_each(&:update_cache_from_timeslices)
  end

  def self.update_all_caches_from_timeslices(articles_courses)
    articles_courses.find_each(&:update_cache_from_timeslices)
  end

  def self.update_from_course_revisions(course, revisions)
    revisions = revisions.select(&:scoped)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = article_ids_by_namespaces_from_revisions(course, revisions)

    # Add new ArticlesCourses
    # Using `insert_all` is massively more efficient than inserting them one at a time.
    article_ids_without_ac = revision_article_ids - course_article_ids
    tracked_wiki_ids = course.wikis.pluck(:id)
    new_article_ids = Article.where(id: article_ids_without_ac, wiki_id: tracked_wiki_ids)
                             .pluck(:id)
    new_records = new_article_ids.map do |id|
      { article_id: id, course_id: course.id }
    end

    maybe_insert_new_records(new_records)
  end

  def self.maybe_insert_new_records(new_records)
    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      # rubocop:disable Rails/SkipsModelValidations
      insert_all new_record_slice
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def self.article_ids_by_namespaces_from_revisions(course, revisions)
    article_ids_from_revisions = revisions.map(&:article_id)
    articles_from_revisions = Article.where(id: article_ids_from_revisions)
    # Return article ids from revisions corresponding to tracked wikis and namespaces
    article_ids = []
    course.tracked_namespaces.map do |wiki_ns|
      wiki = wiki_ns[:wiki]
      namespace = wiki_ns[:namespace]
      article_ids << articles_from_revisions.where(wiki:, namespace:)
                                            .distinct.pluck(:id)
    end
    return article_ids.flatten
  end
end
