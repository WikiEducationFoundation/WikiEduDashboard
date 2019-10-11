class WikidataSummaryParser
  def self.analyze_revisions(revisions)
    claims_created = revisions.select { |r| new(r.summary).created_claim? }.count
    puts "claims created: #{claims_created}"
    claims_changed = revisions.select { |r| new(r.summary).changed_claim? }.count
    puts "claims changed: #{claims_changed}"
    claims_removed = revisions.select { |r| new(r.summary).removed_claim? }.count
    puts "claims removed: #{claims_removed}"
    items_created = revisions.select { |r| new(r.summary).created_item? }.count
    puts "items created: #{items_created}"
    labels_added = revisions.select { |r| new(r.summary).added_label? }.count
    puts "labels added: #{labels_added}"
    descriptions_added = revisions.select { |r| new(r.summary).added_description? }.count
    puts "descriptions added: #{descriptions_added}"
    merged_from = revisions.select { |r| new(r.summary).merged_from? }.count
    puts "merged from: #{merged_from}"
    merged_to = revisions.select { |r| new(r.summary).merged_to? }.count
    puts "merged to: #{merged_to}"
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
    data.data['pages'].values.first['revisions'].first['comment']
  end

  def initialize(summary)
    @summary = summary
  end

  def unknown?
    !created_claim? &&
      !changed_claim? &&
      !removed_claim? &&
      !added_alias? &&
      !changed_alias? &&
      !added_description? &&
      !changed_description? &&
      !added_label? &&
      !changed_label? &&
      !created_item? &&
      !merged_from? &&
      !merged_to? &&
      !unknown_update?
  end

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

  def added_description?
    @summary.include? 'wbsetdescription-add'
  end

  def changed_description?
    @summary.include? 'wbsetdescription-set'
  end

  def added_label?
    @summary.include? 'wbsetlabel-add'
  end

  def changed_label?
    @summary.include? 'wbsetlabel-set'
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
end
