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
end
