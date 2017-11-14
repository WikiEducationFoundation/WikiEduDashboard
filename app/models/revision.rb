# frozen_string_literal: true

# == Schema Information
#
# Table name: revisions
#
#  id             :integer          not null, primary key
#  characters     :integer          default(0)
#  created_at     :datetime
#  updated_at     :datetime
#  user_id        :integer
#  article_id     :integer
#  views          :integer          default(0)
#  date           :datetime
#  new_article    :boolean          default(FALSE)
#  deleted        :boolean          default(FALSE)
#  wp10           :float(24)
#  wp10_previous  :float(24)
#  system         :boolean          default(FALSE)
#  ithenticate_id :integer
#  wiki_id        :integer
#  mw_rev_id      :integer
#  mw_page_id     :integer
#  features       :text(65535)
#

#= Revision model
class Revision < ActiveRecord::Base
  belongs_to :user
  belongs_to :article
  belongs_to :wiki
  scope :live, -> { where(deleted: false) }
  scope :user, -> { where(system: false) }

  # Helps with importing data
  alias_attribute :rev_id, :mw_rev_id

  validates :mw_page_id, presence: true
  validates :mw_rev_id, presence: true
  validates :wiki_id, presence: true

  serialize :features, Hash

  include ArticleHelper

  ####################
  # Instance methods #
  ####################

  # Returns the web diff url for the revision, e.g.,
  # https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945
  def url
    return if article.nil?
    title = article.escaped_full_title
    "#{wiki.base_url}/w/index.php?title=#{title}&diff=prev&oldid=#{mw_rev_id}"
  end

  # Returns all of the revision author's courses where the revision occured
  # within the course start/end dates.
  def infer_courses_from_user
    return [] if user.blank?
    user.courses.where('start <= ?', date).where('end >= ?', date)
  end

  # Returns a link to the plagiarism report for a revision, if there is one.
  def plagiarism_report_link
    return unless ithenticate_id
    "/recent-activity/plagiarism/report?ithenticate_id=#{ithenticate_id}"
  end
end
