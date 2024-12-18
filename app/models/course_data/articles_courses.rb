# frozen_string_literal: true
# == Schema Information
#
# Table name: articles_courses
#
#  id               :integer          not null, primary key
#  created_at       :datetime
#  updated_at       :datetime
#  article_id       :integer
#  course_id        :integer
#  view_count       :bigint           default(0)
#  character_sum    :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  references_count :integer          default(0)
#  tracked          :boolean          default(TRUE)
#  user_ids         :text(65535)
#  first_revision   :datetime
#  revision_count   :integer          default(0)
#

require_dependency "#{Rails.root}/lib/timeslice_manager"

#= ArticlesCourses is a join model between Article and Course.
#= It represents a mainspace Wikipedia article that has been worked on by a
#= student in a course.
class ArticlesCourses < ApplicationRecord # rubocop:disable Metrics/ClassLength
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

  def update_cache_from_timeslices
    self.revision_count = article_course_timeslices.sum(&:revision_count)
    self.character_sum = article_course_timeslices.sum(&:character_sum)
    self.references_count = article_course_timeslices.sum(&:references_count)
    self.user_ids = article_course_timeslices.sum([], &:user_ids).uniq
    self.new_article = article_course_timeslices.any?(&:new_article)
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

  def self.update_all_caches(articles_courses)
    articles_courses.find_each(&:update_cache)
  end

  def self.update_required_caches_from_timeslices(course)
    ArticlesCourses.where(article_id: articles_courses_to_update(course))
                   .find_each(&:update_cache_from_timeslices)
  end

  def self.update_all_caches_from_timeslices(articles_courses)
    articles_courses.find_each(&:update_cache_from_timeslices)
  end

  def self.update_from_course(course)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = article_ids_by_namespaces(course)

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

    return if new_records.empty?
    # Do this is batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      # rubocop:disable Rails/SkipsModelValidations
      insert_all new_record_slice
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def self.update_from_course_revisions(course, revisions)
    course_article_ids = course.articles.where(wiki: course.wikis).pluck(:id)
    revision_article_ids = article_ids_by_namespaces_from_revisions(course, revisions)

    # Remove all the ArticlesCourses that do not correspond to course revisions.
    # That may happen if the course dates changed, so some revisions are no
    # longer part of the course.
    # Also remove records for articles that aren't on a tracked wiki.
    # valid_article_ids = revision_article_ids & course_article_ids
    # destroy_invalid_records(course, valid_article_ids)
    # TODO: changes on course dates or tracked wikis should trigger recalculations
    # or calculations of new timeslices.

    # Add new ArticlesCourses
    # Using `insert_all` is massively more efficient than inserting them one at a time.
    article_ids_without_ac = revision_article_ids - course_article_ids
    tracked_wiki_ids = course.wikis.pluck(:id)
    new_article_ids = Article.where(id: article_ids_without_ac, wiki_id: tracked_wiki_ids)
                             .pluck(:id)
    first_revisions = get_first_revisions(revisions, new_article_ids)
    new_records = new_article_ids.map do |id|
      { article_id: id, course_id: course.id, first_revision: first_revisions[id] }
    end

    maybe_insert_new_records(course, new_records)
  end

  # Given an array of revisions and an array of article ids,
  # it returns a hash with the min revision datetime for every article id.
  def self.get_first_revisions(revisions, new_article_ids)
    # This is the only way I found to get an always-greater value
    max_time = Time.utc(9999, 12, 31)
    min_dates = Hash.new(max_time)

    revisions.each do |revision|
      if new_article_ids.include?(revision.article_id)
        min_dates[revision.article_id] = [min_dates[revision.article_id], revision.date].min
      end
    end
    min_dates
  end

  def self.maybe_insert_new_records(_course, new_records)
    return if new_records.empty?
    # Do this in batches to avoid running the MySQL server out of memory
    new_records.each_slice(5000) do |new_record_slice|
      # rubocop:disable Rails/SkipsModelValidations
      insert_all new_record_slice
      # rubocop:enable Rails/SkipsModelValidations
    end
  end

  def self.destroy_invalid_records(course, valid_article_ids)
    course_ac_records = course.articles_courses.pluck(:id, :article_id)
    course_ac_records.each do |(id, article_id)|
      next if valid_article_ids.include?(article_id)
      find(id).destroy
    end
  end

  def self.article_ids_by_namespaces(course)
    # Return article ids from revisions corresponding to tracked wikis and namespaces
    article_ids = []
    course.tracked_namespaces.map do |wiki_ns|
      wiki = wiki_ns[:wiki]
      namespace = wiki_ns[:namespace]
      article_ids << course.revisions.joins(:article).where(articles: { wiki:, namespace: })
                           .distinct.pluck(:article_id)
    end
    return article_ids.flatten
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
