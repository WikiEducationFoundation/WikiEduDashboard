# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id               :bigint           not null, primary key
#  start            :datetime
#  end              :datetime
#  last_mw_rev_id   :integer
#  character_sum    :integer          default(0)
#  references_count :integer          default(0)
#  user_ids         :text(65535)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  article_id       :integer          not null
#  course_id        :integer          not null
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

  serialize :user_ids, Array # This text field only stores user ids as text

  #################
  # Class methods #
  #################

  # Search by course and user.
  def self.search_by_course_and_user(course, user_id)
    ArticleCourseTimeslice.where(course:).where('user_ids LIKE ?', "%- #{user_id}\n%")
  end

  # Given a course, an article, and a hash of revisions like the following:
  # {:start=>"20160320", :end=>"20160401", :revisions=>[...]},
  # updates the article course timeslices based on the revisions.
  def self.update_article_course_timeslices(course, article_id, revisions)
    rev_start = revisions[:start]
    rev_end = revisions[:end]
    # Article course timeslices to update
    article_course_timeslices = ArticleCourseTimeslice.for_course_and_article(course,
                                                                              article_id)
                                                      .for_revisions_between(rev_start, rev_end)
    article_course_timeslices.each do |timeslice|
      # Group revisions that belong to the timeslice
      revisions_in_timeslice = revisions[:revisions].select do |revision|
        timeslice.start <= revision.date && revision.date < timeslice.end
      end
      # Update cache for ArticleCourseTimeslice
      timeslice.update_cache_from_revisions revisions_in_timeslice
    end
  end

  ####################
  # Instance methods #
  ####################

  # Takes an array of revisions for the article_course_timeslice
  def update_cache_from_revisions(revisions)
    # Filter the deleted revisions
    live_revisions = revisions.reject { |r| r.deleted || r.system }
    self.character_sum = live_revisions.sum { |r| r.characters.to_i.positive? ? r.characters : 0 }
    self.references_count = live_revisions.sum(&:references_added)
    self.user_ids = associated_user_ids(live_revisions)
    save
  end

  private

  def associated_user_ids(revisions)
    return [] if revisions.blank?
    revisions.filter_map(&:user_id).uniq
  end
end
