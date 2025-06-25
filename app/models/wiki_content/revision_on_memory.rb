# frozen_string_literal: true

class RevisionOnMemory
  include ActiveModel::Model
  # Helps with importing data
  alias_attribute :rev_id, :mw_rev_id

  validates :mw_page_id, presence: true
  validates :mw_rev_id, presence: true

  attr_accessor :mw_rev_id, :date, :characters, :article_id, :mw_page_id, :user_id, :new_article,
                :system, :wiki_id, :scoped, :features, :features_previous, :summary, :error

  ####################
  # Instance methods #
  ####################

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

  # This function parses the serialized stats saved in the summary field, in case of any errors
  # it returns nil meaning the field contains an edit summary
  def diff_stats
    JSON.parse(summary) if summary.present? && summary.start_with?('{', '[')
  rescue JSON::ParserError
    nil # Return nil if parsing fails (i.e., not diff_stats)
  end
end
