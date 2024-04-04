# frozen_string_literal: true
# == Schema Information
#
# Table name: revisions
#
#  id                :integer          not null, primary key
#  characters        :integer          default(0)
#  created_at        :datetime
#  updated_at        :datetime
#  user_id           :integer
#  article_id        :integer
#  views             :bigint           default(0)
#  date              :datetime
#  new_article       :boolean          default(FALSE)
#  deleted           :boolean          default(FALSE)
#  wp10              :float(24)
#  wp10_previous     :float(24)
#  system            :boolean          default(FALSE)
#  ithenticate_id    :integer
#  wiki_id           :integer
#  mw_rev_id         :integer
#  mw_page_id        :integer
#  features          :text(65535)
#  features_previous :text(65535)
#  summary           :text(65535)
#
require 'json'
#= Revision model
class Revision < ApplicationRecord
  belongs_to :user
  belongs_to :article
  belongs_to :wiki
  scope :live, -> { where(deleted: false) }
  scope :user, -> { where(system: false) }
  scope :suspected_plagiarism, -> { where.not(ithenticate_id: nil) }
  scope :namespace, ->(ns) { joins(:article).where(articles: { namespace: ns }) }

  # Helps with importing data
  alias_attribute :rev_id, :mw_rev_id

  validates :mw_page_id, presence: true
  validates :mw_rev_id, presence: true

  serialize :features, Hash
  serialize :features_previous, Hash

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

  # reference-counter API value
  REFERENCE_COUNT = 'num_ref'
  # LiftWing API values
  WIKITEXT_REF_TAGS = 'feature.wikitext.revision.ref_tags'
  WIKIDATA_REFERENCES = 'feature.len(<datasource.wikidatawiki.revision.references>)'
  WIKI_SHORTENED_REF_TAGS = 'feature.enwiki.revision.shortened_footnote_templates'

  # Returns the number of references for a given revision id, based on its features.
  # If REFERENCE_COUNT field is present, then use it. This number of references comes from
  # the reference-counter API.
  # Otherwise, it uses values from the LiftWing API.
  def references_count(rev_features)
    return nil if rev_features.empty?
    rev_features[REFERENCE_COUNT] ||
      ((rev_features[WIKITEXT_REF_TAGS] || rev_features[WIKIDATA_REFERENCES] || 0) +
        (rev_features[WIKI_SHORTENED_REF_TAGS] || 0))
  end

  def references_added
    return (references_count(features) || 0) if new_article
    return 0 unless references_count(features) && references_count(features_previous)
    references_count(features) - references_count(features_previous)
  end

  # Generally, the summary field captured edit summary comment of an edit until August 2023
  # This code is for a switch to save diff_stats instead(output hash generated from
  # wikidata-diff-analyzer gem)
  # These two methods find out if the content in summary field is a stats_hash or not
  # Edits made before August 2023 will be handled through WikidataSummaryParser and
  # the later edits will be handled by stats collected from wikidata-diff-analyzer

  def edit_summary
    return summary unless diff_stats # If diff_stats is nil, then summary is the edit summary
    nil # Otherwise, it's diff_stats and returns nil
  end

  # This function parses the serialized stats saved in the summary field, in case of any errors
  # it returns nil meaning the field contains an edit summary
  def diff_stats
    JSON.parse(summary) if summary.present? && summary.start_with?('{', '[')
  rescue JSON::ParserError
    nil # Return nil if parsing fails (i.e., not diff_stats)
  end
end
