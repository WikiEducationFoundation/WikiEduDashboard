# frozen_string_literal: true
# == Schema Information
#
# Table name: article_course_timeslices
#
#  id                :bigint           not null, primary key
#  article_id        :integer          not null
#  course_id         :integer          not null
#  start             :datetime
#  end               :datetime
#  last_mw_rev_id    :integer
#  character_sum     :integer          default(0)
#  references_count  :integer          default(0)
#  user_ids          :text(65535)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
class ArticleCourseTimeslice < ApplicationRecord
  belongs_to :article
  belongs_to :course

  scope :non_empty, -> { where.not(user_ids: nil) }
  serialize :user_ids, Array # This text field only stores user ids as text

  ####################
  # Instance methods #
  ####################

  # Takes an array of revisions for the article_course_timeslice
  def update_cache_from_revisions(revisions)
    # Filter the deleted revisions
    live_revisions = revisions.reject(&:deleted)
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
