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

  WIKITEXT_REF_TAGS = 'feature.wikitext.revision.ref_tags'
  WIKIDATA_REFERENCES = 'feature.len(<datasource.wikidatawiki.revision.references>)'
  WIKI_SHORTENED_REF_TAGS = 'feature.enwiki.revision.shortened_footnote_templates'

  def references_count(ores_features)
    return nil if ores_features.empty?
    (ores_features[WIKITEXT_REF_TAGS] || ores_features[WIKIDATA_REFERENCES] || 0) +
      (ores_features[WIKI_SHORTENED_REF_TAGS] || 0)
  end

  def references_added
    return (references_count(features) || 0) if new_article
    return 0 unless references_count(features) && references_count(features_previous)
    references_count(features) - references_count(features_previous)
  end

  def edit_summary
    return summary unless diff_stats # If diff_stats is nil, then summary is the edit summary
    nil # Otherwise, it's diff_stats and returns nil
  end

  def diff_stats
    JSON.parse(summary) if summary.present? && summary.start_with?('{', '[')
  rescue JSON::ParserError
    nil # Return nil if parsing fails (i.e., not diff_stats)
  end
end
