# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
class WikidataSummaryParser
  REVISION_CLASSIFICATIONS = {
    'claims created' => :created_claim?,
    'claims changed' => :changed_claim?,
    'claims removed' => :removed_claim?,
    'items created' => :created_item?,
    'lexeme items created' => :created_lexeme_item?,
    'labels added' => :added_label?,
    'labels changed' => :changed_label?,
    'labels removed' => :removed_label?,
    'descriptions added' => :added_description?,
    'descriptions changed' => :changed_description?,
    'descriptions removed' => :removed_description?,
    'aliases added' => :added_alias?,
    'aliases changed' => :changed_alias?,
    'aliases removed' => :removed_alias?,
    'merged from' => :merged_from?,
    'merged to' => :merged_to?,
    'interwiki links added' => :added_interwiki_link?,
    'interwiki links removed' => :removed_interwiki_link?,
    'interwiki links updated' => :updated_interwiki_link?,
    'redirects created' => :created_redirect?,
    'reverts performed' => :reverted_an_edit?,
    'restorations performed' => :restored_revision?,
    'items cleared' => :cleared_item?,
    'qualifiers added' => :added_qualifier?,
    'references added' => :added_reference?,
    'other updates' => :unknown_update?,
    'unknown' => :unknown?,
    'no data' => :no_data?
  }.freeze

  def self.analyze_revisions(revisions)
    stats = {}
    REVISION_CLASSIFICATIONS.each do |label, method|
      stats[label] = revisions.count { |r| new(r.summary).send(method) }
    end
    stats['total revisions'] = stats.values.sum
    stats
  end

  def initialize(summary)
    @summary = summary || ''
  end

  # Almost all edits to Items have standard identifiers in the summary,
  # but Wikidata edits to non-Item pages (like userpages) can have arbitrary
  # edit summaries. Most of the 'unknown' edits should be edits outside of
  # the Item namespace, but that may change over time if new identifiers
  # are added that we don't handle here yet.
  # rubocop:disable Metrics/PerceivedComplexity
  def unknown?
    !created_claim? &&
      !changed_claim? &&
      !removed_claim? &&
      !added_alias? &&
      !changed_alias? &&
      !removed_alias? &&
      !added_description? &&
      !changed_description? &&
      !removed_description? &&
      !added_label? &&
      !changed_label? &&
      !removed_label? &&
      !created_item? &&
      !created_lexeme_item? &&
      !merged_from? &&
      !merged_to? &&
      !added_interwiki_link? &&
      !removed_interwiki_link? &&
      !updated_interwiki_link? &&
      !created_redirect? &&
      !reverted_an_edit? &&
      !cleared_item? &&
      !restored_revision? &&
      !added_qualifier? &&
      !added_reference? &&
      !unknown_update?
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def no_data?
    @summary.empty?
  end

  def created_claim?
    @summary.include?('wbsetclaim-create') ||
      @summary.include?('wbcreateclaim-create')
  end

  def changed_claim?
    @summary.include? 'wbsetclaim-update'
  end

  def removed_claim?
    @summary.include? 'wbremoveclaims-remove'
  end

  def added_alias?
    @summary.include? 'wbsetaliases-add'
  end

  def changed_alias?
    @summary.include? 'wbsetaliases-update'
  end

  def removed_alias?
    @summary.include? 'wbsetaliases-remove'
  end

  def added_description?
    @summary.include? 'wbsetdescription-add'
  end

  def changed_description?
    @summary.include? 'wbsetdescription-set'
  end

  def removed_description?
    @summary.include? 'wbsetdescription-remove'
  end

  def added_label?
    @summary.include? 'wbsetlabel-add'
  end

  def changed_label?
    @summary.include? 'wbsetlabel-set'
  end

  def removed_label?
    @summary.include? 'wbsetlabel-remove'
  end

  def created_item?
    @summary.include?('wbeditentity-create') &&
      @summary.exclude?('wbeditentity-create-lexeme')
  end

  def created_lexeme_item?
    @summary.include? 'wbeditentity-create-lexeme'
  end

  # This edit summary can mean adding a claim, but it seems to be generic for edits
  # made via Widar and possibly other tools.
  def unknown_update?
    @summary.include? 'wbeditentity-update'
  end

  def merged_from?
    @summary.include? 'wbmergeitems-from'
  end

  def merged_to?
    @summary.include? 'wbmergeitems-to'
  end

  def added_interwiki_link?
    @summary.include? 'wbsetsitelink-add'
  end

  def removed_interwiki_link?
    @summary.include? 'wbsetsitelink-remove'
  end

  def updated_interwiki_link?
    @summary.include? 'clientsitelink-update'
  end

  def created_redirect?
    @summary.include? 'wbcreateredirect'
  end

  def reverted_an_edit?
    @summary.include? 'undo:'
  end

  def cleared_item?
    @summary.include? 'wbeditentity-override'
  end

  def added_qualifier?
    @summary.include? 'wbsetqualifier-add'
  end

  def restored_revision?
    @summary.include? 'restore:'
  end

  def added_reference?
    @summary.include? 'wbsetreference-add'
  end
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
