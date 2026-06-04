# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_user_wiki_timeslices
#
#  id               :bigint           not null, primary key
#  course_id        :integer          not null
#  wiki_id          :integer          not null
#  article_id       :integer          not null
#  user_id          :integer          not null
#  start            :datetime
#  end              :datetime
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  revision_count   :integer          default(0)
#  new_article      :boolean          default(FALSE)
#  tracked          :boolean          default(TRUE)
#  first_revision   :datetime
#  stats            :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class ArticleCourseUserWikiTimeslice < ApplicationRecord
  belongs_to :article
  belongs_to :course
  belongs_to :user
  belongs_to :wiki

  scope :for_course_article_user_and_wiki,
        ->(course, article, user, wiki) { where(course:, article:, user:, wiki:) }
  # Returns the timeslice to which a datetime belongs (it should be a single timeslice)
  scope :for_datetime, ->(datetime) { where('start <= ? AND end > ?', datetime, datetime) }
  # Returns all the timeslices in a given period
  scope :in_period, lambda { |period_start, period_end|
    where('start >= ? AND end <= ?', period_start, period_end)
  }
  scope :for_revisions_between, lambda { |period_start, period_end|
    in_period(period_start, period_end).or(for_datetime(period_start)).or(for_datetime(period_end))
  }

  serialize :stats, type: Hash

  #################
  # Class methods #
  #################

  # Given a course, an article_id, a user_id, a wiki, and a hash of revisions like the following:
  # {:start=>"20160320000000", :end=>"20160320235959", :revisions=>[...]},
  # where start and end span a single timeslice period (end is 1 second
  # before the next timeslice boundary), updates the article course user wiki timeslice.
  def self.update_article_course_user_wiki_timeslices(course, article_id, user_id, wiki, revisions)
    timeslices = course.course_wiki_timeslices.where(wiki:)
                       .for_revisions_between(revisions[:start], revisions[:end])
    if timeslices.size > 1
      message = "Multiple article course user wiki timeslices matched for course #{course.slug}"
      Sentry.capture_message message,
                             level: 'error',
                             extra: { course_id: course.id, wiki_id: wiki.id, article_id:, user_id:,
                                      start: revisions[:start], end: revisions[:end] }
    end
    timeslice = timeslices.first
    acuw_timeslice = find_or_create_by(course:, article_id:, user_id:, wiki:,
                                       start: timeslice.start, end: timeslice.end)
    acuw_timeslice.update_cache_from_revisions revisions[:revisions]
  end

  # Bulk-upsert ACUWT rows for a single timeslice window from an array of revision objects.
  # Replaces the per-(article, user) find_or_create_by + save loop with one upsert_all call.
  def self.bulk_upsert_from_revisions(course, wiki, ts_start, ts_end, revisions)
    records = acuwt_records_from_revisions(course, wiki, ts_start, ts_end, revisions)
    return if records.empty?
    upsert_all(records,
               update_only: %i[revision_count character_sum references_count new_article
                               first_revision stats updated_at])
  end

  ####################
  # Instance methods #
  ####################

  def update_cache_from_revisions(revisions)
    live_revisions = revisions.reject { |r| r.deleted || r.system }
    self.revision_count = live_revisions.size
    self.character_sum = character_sum_for(live_revisions)
    self.references_count = live_revisions.sum(&:references_added)
    self.new_article = revisions.any?(&:new_article)
    self.first_revision = live_revisions.map(&:date).min
    self.stats = update_wikidata_stats(live_revisions) if wiki.project == 'wikidata'
    save
  end

  private

  def character_sum_for(revisions)
    revisions.sum { |r| r.characters.to_i.positive? ? r.characters : 0 }
  end

  def update_wikidata_stats(revisions)
    UpdateWikidataStatsTimeslice.new(course).build_stats_from_revisions(revisions)
  end

  def self.acuwt_records_from_revisions(course, wiki, ts_start, ts_end, revisions)
    now = Time.current
    base = { course_id: course.id, wiki_id: wiki.id, start: ts_start, end: ts_end }
    revisions
      .reject { |r| r.article_id.nil? || r.user_id.nil? }
      .group_by { |r| [r.article_id, r.user_id] }
      .map do |(article_id, user_id), revs|
        live = revs.reject { |r| r.deleted || r.system }
        { **base, article_id:, user_id:, created_at: now, updated_at: now,
          **acuwt_revision_stats(course, wiki, revs, live) }
      end
  end
  private_class_method :acuwt_records_from_revisions

  def self.acuwt_revision_stats(course, wiki, revs, live)
    { revision_count: live.size,
      character_sum: live.sum { |r| r.characters.to_i.positive? ? r.characters : 0 },
      references_count: live.sum(&:references_added),
      new_article: revs.any?(&:new_article),
      first_revision: live.map(&:date).min,
      stats: acuwt_wikidata_stats(course, wiki, live) }
  end
  private_class_method :acuwt_revision_stats

  def self.acuwt_wikidata_stats(course, wiki, live_revisions)
    return unless wiki.project == 'wikidata'
    UpdateWikidataStatsTimeslice.new(course).build_stats_from_revisions(live_revisions)
  end
  private_class_method :acuwt_wikidata_stats
end
