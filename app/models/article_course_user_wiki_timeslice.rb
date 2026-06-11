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
#  needs_update     :boolean          default(FALSE)
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

  # Returns distinct (start, end) pairs for rows matching the given course, wiki, and articles.
  # Used by UpdateTimeslicesScopedArticle to iterate over timeslice windows that need rescoring.
  def self.periods_for_articles(course, wiki, article_ids)
    where(course:, wiki:, article_id: article_ids)
      .distinct.pluck(:start, :end)
  end

  # Returns Users who have ACUWT rows for the given course, wiki, articles, and period start.
  # Used by UpdateTimeslicesScopedArticle to find which users to re-fetch revisions for.
  def self.users_for_articles_in_period(course, wiki, article_ids, ts_start)
    user_ids = where(course:, wiki:, article_id: article_ids, start: ts_start)
                 .distinct.pluck(:user_id)
    User.where(id: user_ids)
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
