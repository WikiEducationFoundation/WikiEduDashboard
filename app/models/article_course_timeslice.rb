# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  article_id       :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  user_ids         :text(65535)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  first_revision   :datetime
#
class ArticleCourseTimeslice < ApplicationRecord
  belongs_to :article
  belongs_to :course

  scope :non_empty, -> { where.not(user_ids: nil) }
  scope :for_course_and_article, ->(course, article) { where(course:, article:) }
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

  # Search by course and user.
  def self.search_by_course_and_user(course, user_id)
    ArticleCourseTimeslice.where(course:).where('user_ids LIKE ?', "%- #{user_id}\n%")
  end

  # Given a course, an article, and a hash of revisions like the following:
  # {:start=>"20160320000000", :end=>"20160320235959", :revisions=>[...]},
  # where start and end span a single timeslice period (end is 1 second
  # before the next timeslice boundary), updates the article course timeslice.
  def self.update_article_course_timeslices(course, article_id, revisions)
    wiki_id = revisions[:revisions].first.wiki_id

    # For debugging purposes only. TODO: delete this sentry message log
    log_nil_article_id(course, article_id, wiki_id, revisions) if article_id.nil?

    timeslices = course.course_wiki_timeslices.where(wiki_id:)
                       .for_revisions_between(revisions[:start], revisions[:end])
    if timeslices.size > 1
      message = "Multiple article course timeslices matched for course #{course.slug}"
      Sentry.capture_message message,
                             level: 'error',
                             extra: { course_id: course.id, wiki_id:, article_id:,
                                      start: revisions[:start], end: revisions[:end] }
    end
    timeslice = timeslices.first
    ac_timeslice = find_or_create_by(course:, article_id:,
                                     start: timeslice.start, end: timeslice.end)
    ac_timeslice.update_cache_from_revisions revisions[:revisions]
  end

  def self.update_from_acuwt(course, article_id, wiki, start, finish)
    acuwt_records = ArticleCourseUserWikiTimeslice
                      .where(course:, article_id:, wiki:, start:, end: finish)
    ac_timeslice = find_or_create_by(course:, article_id:, start:, end: finish)
    ac_timeslice.update_cache_from_acuwt(acuwt_records)
  end

  # Bulk-update ACT rows for a single timeslice window from stored ACUWT records.
  # Replaces the per-article find_or_create_by + N aggregate queries with one SELECT
  # (all ACUWT for the window) + one upsert_all.
  def self.bulk_update_from_acuwt(course, wiki, ts_start, ts_end)
    records = act_records_from_acuwt(course, wiki, ts_start, ts_end)
    return if records.empty?
    upsert_all(records,
               update_only: %i[revision_count character_sum references_count
                               user_ids new_article first_revision updated_at])
  end

  def self.log_nil_article_id(course, article_id, wiki_id, revisions)
    Sentry.capture_message "Article id nil for course #{course.id}",
                           level: 'error',
                           extra: {
                             wiki_id:,
                             mw_page_ids: revisions[:revisions].map(&:mw_page_id),
                             revision_ids: revisions[:revisions].map(&:mw_rev_id)
                           }
  end
  private_class_method :log_nil_article_id

  ####################
  # Instance methods #
  ####################

  # Takes an array of revisions for the article_course_timeslice
  def update_cache_from_revisions(revisions)
    # Filter the deleted revisions
    live_revisions = revisions.reject { |r| r.deleted || r.system }
    self.revision_count = live_revisions.size
    self.character_sum = live_revisions.sum { |r| r.characters.to_i.positive? ? r.characters : 0 }
    self.references_count = live_revisions.sum(&:references_added)
    self.user_ids = associated_user_ids(live_revisions)
    self.new_article = revisions.any?(&:new_article)
    # first_revision may be nil if revision count is 0
    self.first_revision = live_revisions.minimum(:date)
    save
  end

  def update_cache_from_acuwt(acuwt_records)
    self.revision_count = acuwt_records.sum(:revision_count)
    self.character_sum = acuwt_records.sum(:character_sum)
    self.references_count = acuwt_records.sum(:references_count)
    self.user_ids = acuwt_records.where('revision_count > 0').pluck(:user_id)
    self.new_article = acuwt_records.where(new_article: true).exists?
    self.first_revision = acuwt_records.minimum(:first_revision)
    save
  end

  def self.act_records_from_acuwt(course, wiki, ts_start, ts_end)
    now = Time.current
    base = { course_id: course.id, start: ts_start, end: ts_end }
    ArticleCourseUserWikiTimeslice
      .where(course:, wiki:, start: ts_start, end: ts_end)
      .group_by(&:article_id)
      .map do |article_id, rows|
        { **base, article_id:, created_at: now, updated_at: now,
          **act_stats_from_acuwt(rows) }
      end
  end
  private_class_method :act_records_from_acuwt

  def self.act_stats_from_acuwt(rows)
    { revision_count: rows.sum(&:revision_count),
      character_sum: rows.sum(&:character_sum),
      references_count: rows.sum(&:references_count),
      user_ids: rows.select { |r| r.revision_count.positive? }.map(&:user_id),
      new_article: rows.any?(&:new_article),
      first_revision: rows.map(&:first_revision).compact.min }
  end
  private_class_method :act_stats_from_acuwt

  private

  def associated_user_ids(revisions)
    return [] if revisions.blank?
    revisions.filter_map(&:user_id).uniq
  end
end
