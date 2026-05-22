# frozen_string_literal: true

# == Schema Information
#
# Table name: course_user_wiki_timeslices
#
#  id                  :bigint           not null, primary key
#  course_id           :integer          not null
#  user_id             :integer          not null
#  wiki_id             :integer          not null
#  start               :datetime
#  end                 :datetime
#  character_sum_ms    :integer          default(0)
#  character_sum_us    :integer          default(0)
#  character_sum_draft :integer          default(0)
#  references_count    :integer          default(0)
#  revision_count      :integer          default(0)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
class CourseUserWikiTimeslice < ApplicationRecord
  belongs_to :course
  belongs_to :user
  belongs_to :wiki
  scope :for_course_user_and_wiki, ->(course, user, wiki) { where(course:, user:, wiki:) }
  # Returns the timeslice to which a datetime belongs (it should be a single timeslice)
  scope :for_datetime, ->(datetime) { where('start <= ? AND end > ?', datetime, datetime) }
  # Returns all the timeslices in a given period
  scope :in_period, lambda { |period_start, period_end|
                      where('start >= ? AND end <= ?', period_start, period_end)
                    }
  scope :for_revisions_between, lambda { |period_start, period_end|
    in_period(period_start, period_end).or(for_datetime(period_start)).or(for_datetime(period_end))
  }

  serialize :user_ids, type: Array # This text field only stores user ids as text

  #################
  # Class methods #
  #################

  # Given a course, a user_id, a wiki and a hash of revisions like the following:
  # {:start=>"20160320000000", :end=>"20160320235959", :revisions=>[...]},
  # where start and end span a single timeslice period (end is 1 second
  # before the next timeslice boundary), updates the course user wiki timeslice.
  def self.update_course_user_wiki_timeslices(course, user_id, wiki, revisions)
    timeslices = course.course_wiki_timeslices.where(wiki:)
                       .for_revisions_between(revisions[:start], revisions[:end])
    if timeslices.size > 1
      message = "Multiple course user wiki timeslices matched for course #{course.slug}"
      Sentry.capture_message message,
                             level: 'error',
                             extra: { course_id: course.id, wiki_id: wiki.id, user_id:,
                                      start: revisions[:start], end: revisions[:end] }
    end
    timeslice = timeslices.first
    cu_timeslice = find_or_create_by(course:, user_id:, wiki:,
                                     start: timeslice.start, end: timeslice.end)
    cu_timeslice.update_cache_from_revisions revisions[:revisions]
  end

  def self.update_from_acuwt(course, user_id, wiki, start, finish)
    acuwt_records = ArticleCourseUserWikiTimeslice
                      .where(course:, user_id:, wiki:, start:, end: finish)
    cu_timeslice = find_or_create_by(course:, user_id:, wiki:, start:, end: finish)
    cu_timeslice.update_cache_from_acuwt(acuwt_records)
  end

  ####################
  # Instance methods #
  ####################

  # Assumes that the revisions are for their own course user wiki
  def update_cache_from_revisions(revisions)
    # Only work with scoped revisions
    @revisions = revisions.select(&:scoped)
    @liverevisions = live_revisions
    tracked_namespace_revisions = live_revisions_in_tracked_namespaces
    update_character_sum(@liverevisions, tracked_namespace_revisions)
    self.references_count = references_sum(tracked_namespace_revisions)

    self.revision_count = filtered_live_revisions.size || 0
    save
  end

  def update_cache_from_acuwt(acuwt_records)
    records = acuwt_records.to_a
    excluded_article_ids = course.articles_courses.not_tracked.pluck(:article_id)
    tracked_records = records.reject { |r| excluded_article_ids.include?(r.article_id) }
    by_ns = records_by_namespace(tracked_records)
    update_character_sum_from_acuwt(by_ns)
    self.revision_count = by_ns.except(nil).values.flatten.sum(&:revision_count)
    save
  end

  private

  # Returns tracked revisions (revisions for tracked article courses)
  # for which already exists an article record made for user_id.
  # Notice that revisions are already made for a given user_id
  def live_revisions
    excluded_article_ids = course.articles_courses.not_tracked.pluck(:article_id)
    tracked_revisions = @revisions.reject do |revision|
      excluded_article_ids.include?(revision.article_id)
    end
    # Ensure that article record exists for article_ids
    article_ids = tracked_revisions.map(&:article_id)
    articles_ids_with_article_records = Article.where(id: article_ids).pluck(:id)
    filtered_tracked_revisions = tracked_revisions.select do |revision|
      articles_ids_with_article_records.include?(revision.article_id)
    end
    filtered_tracked_revisions.reject { |r| r.deleted || r.system }
  end

  def live_revisions_in_tracked_namespaces
    course_article_ids = course.articles.pluck(:id)
    live_revisions.select do |revision|
      course_article_ids.include?(revision.article_id)
    end
  end

  def filtered_live_revisions
    article_ids = @liverevisions.map(&:article_id)
    articles = Article.where(id: article_ids, deleted: false)

    # Filter revisions based on the fetched articles
    live_article_ids = articles.pluck(:id)
    @liverevisions.select do |rev|
      live_article_ids.include?(rev.article_id)
    end
  end

  def update_character_sum(revisions, tracked_namespace_revisions)
    self.character_sum_ms = character_sum(tracked_namespace_revisions,
                                          Article::Namespaces::MAINSPACE)
    self.character_sum_us = character_sum(revisions, Article::Namespaces::USER)
    self.character_sum_draft = character_sum(revisions, Article::Namespaces::DRAFT)
  end

  ##################
  # Helper methods #
  ##################

  def character_sum(revisions, namespace)
    article_ids = revisions.map(&:article_id)
    articles = Article.where(id: article_ids, namespace:, deleted: false)

    # Filter revisions based on the fetched articles
    article_ids_in_namespace = articles.pluck(:id)
    filtered_revisions = revisions.select do |rev|
      article_ids_in_namespace.include?(rev.article_id) && rev.characters >= 0
    end

    # Sum characters
    filtered_revisions.sum(&:characters)
  end

  def references_sum(revisions)
    article_ids = revisions.map(&:article_id)
    articles = Article.where(id: article_ids, namespace: Article::Namespaces::MAINSPACE,
                             deleted: false)

    # Filter revisions based on the fetched articles
    article_ids_in_mainspace = articles.pluck(:id)
    filtered_revisions = revisions.select do |rev|
      article_ids_in_mainspace.include?(rev.article_id)
    end
    filtered_revisions.sum(&:references_added)
  end

  def records_by_namespace(records)
    article_ids = records.map(&:article_id)
    articles_by_id = Article.where(id: article_ids, deleted: false).index_by(&:id)
    records.group_by { |r| articles_by_id[r.article_id]&.namespace }
  end

  def update_character_sum_from_acuwt(by_ns)
    ms_records = by_ns[Article::Namespaces::MAINSPACE] || []
    us_records = by_ns[Article::Namespaces::USER] || []
    draft_records = by_ns[Article::Namespaces::DRAFT] || []
    self.character_sum_ms = ms_records.sum(&:character_sum)
    self.character_sum_us = us_records.sum(&:character_sum)
    self.character_sum_draft = draft_records.sum(&:character_sum)
    self.references_count = ms_records.sum(&:references_count)
  end
end
