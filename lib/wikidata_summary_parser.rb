# frozen_string_literal: true

# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/ClassLength
class WikidataSummaryParser
  def self.analyze_revisions(revisions)
    puts "total revisions: #{revisions.count}"
    claims_created = revisions.count { |r| new(r.summary).created_claim? }
    puts "claims created: #{claims_created}"
    claims_changed = revisions.count { |r| new(r.summary).changed_claim? }
    puts "claims changed: #{claims_changed}"
    claims_removed = revisions.count { |r| new(r.summary).removed_claim? }
    puts "claims removed: #{claims_removed}"
    items_created = revisions.count { |r| new(r.summary).created_item? }
    puts "items created: #{items_created}"
    labels_added = revisions.count { |r| new(r.summary).added_label? }
    puts "labels added: #{labels_added}"
    labels_changed = revisions.count { |r| new(r.summary).changed_label? }
    puts "labels changed: #{labels_changed}"
    labels_removed = revisions.count { |r| new(r.summary).removed_label? }
    puts "labels removed: #{labels_removed}"
    descriptions_added = revisions.count { |r| new(r.summary).added_description? }
    puts "descriptions added: #{descriptions_added}"
    descriptions_changed = revisions.count { |r| new(r.summary).changed_description? }
    puts "descriptions changed: #{descriptions_changed}"
    descriptions_removed = revisions.count { |r| new(r.summary).removed_description? }
    puts "descriptions removed: #{descriptions_removed}"
    aliases_added = revisions.count { |r| new(r.summary).added_alias? }
    puts "aliases added: #{aliases_added}"
    aliases_changed = revisions.count { |r| new(r.summary).changed_alias? }
    puts "aliases changed: #{aliases_changed}"
    aliases_removed = revisions.count { |r| new(r.summary).removed_alias? }
    puts "aliases removed: #{aliases_removed}"
    merged_from = revisions.count { |r| new(r.summary).merged_from? }
    puts "merged from: #{merged_from}"
    merged_to = revisions.count { |r| new(r.summary).merged_to? }
    puts "merged to: #{merged_to}"
    added_interwiki = revisions.count { |r| new(r.summary).added_interwiki_link? }
    puts "interwiki links added: #{added_interwiki}"
    removed_interwiki = revisions.count { |r| new(r.summary).removed_interwiki_link? }
    puts "interwiki links removed: #{removed_interwiki}"
    redirects_created = revisions.count { |r| new(r.summary).created_redirect? }
    puts "redirects created: #{redirects_created}"
    reverts = revisions.count { |r| new(r.summary).reverted_an_edit? }
    puts "reverts performed: #{reverts}"
    restorations = revisions.count { |r| new(r.summary).restored_revision? }
    puts "restorations performed: #{restorations}"
    items_cleared = revisions.count { |r| new(r.summary).cleared_item? }
    puts "items cleared: #{items_cleared}"
    qualifiers_added = revisions.count { |r| new(r.summary).added_qualifier? }
    puts "qualifiers added: #{qualifiers_added}"
    other_updates = revisions.count { |r| new(r.summary).unknown_update? }
    puts "other updates: #{other_updates}"
    unknown = revisions.count { |r| new(r.summary).unknown? }
    puts "unknown: #{unknown}"
  end

  def self.analyze_revision(revision)
    new(fetch_summary(revision)).changes
  end

  def self.fetch_summary(revision)
    query = {
      prop: 'revisions',
      rvprop: 'comment',
      revids: revision.mw_rev_id
    }
    data = WikiApi.new(revision.wiki).query(query)
    page_data = data.data['pages']
    # Deleted revisions return data without a 'pages' key, like:
    # {"batchcomplete":"","query":{"badrevids":{"968242606":{"revid":968242606}}}}
    return unless page_data
    page_data.values.first['revisions'].first['comment']
  end

  def initialize(summary)
    @summary = summary
  end

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
      !merged_from? &&
      !merged_to? &&
      !added_interwiki_link? &&
      !removed_interwiki_link? &&
      !created_redirect? &&
      !reverted_an_edit? &&
      !cleared_item? &&
      !restored_revision? &&
      !added_qualifier? &&
      !unknown_update?
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def changes
    {
      created_claim: created_claim?,
      changed_claim: changed_claim?,
      added_alias: added_alias?,
      added_description: added_description?,
      changed_description: changed_description?
    }
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
    @summary.include? 'wbeditentity-create'
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
end
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/ClassLength
