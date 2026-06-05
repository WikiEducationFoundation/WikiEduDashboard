# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# require the installed wikidata-diff-analyzer gem
require 'wikidata-diff-analyzer'

class UpdateWikidataStatsTimeslice
  include ApiErrorHandling
  # This hash contains the keys of the wikidata-diff-analyzer output hash
  # and maps them to the values used in the UI and CourseStat Hash
  STATS_CLASSIFICATION = {
    # UI section: General
    'merge_to' => 'merged to',
    'merge_from' => 'merged from',
    'added_sitelinks' => 'interwiki links added',
    # UI section: Claims
    'added_claims' => 'claims created',
    'removed_claims' => 'claims removed',
    'changed_claims' => 'claims changed',
    # UI section: Items
    'clear_item' => 'items cleared',
    'create_item' => 'items created',
    # UI section: Labels
    'added_labels' => 'labels added',
    'removed_labels' => 'labels removed',
    'changed_labels' => 'labels changed',
    # UI section: Descriptions
    'added_descriptions' => 'descriptions added',
    'removed_descriptions' => 'descriptions removed',
    'changed_descriptions' => 'descriptions changed',
    # UI section: Aliases
    'added_aliases' => 'aliases added',
    'removed_aliases' => 'aliases removed',
    'changed_aliases' => 'aliases changed',
    # UI section: Others
    'added_references' => 'references added',
    'added_qualifiers' => 'qualifiers added',
    'redirect' => 'redirects created',
    'undo' => 'reverts performed',
    'restore' => 'restorations performed',
    # UI section: Not added yet
    'removed_references' => 'references removed',
    'changed_references' => 'references changed',
    'removed_qualifiers' => 'qualifiers removed',
    'changed_qualifiers' => 'qualifiers changed',
    'removed_sitelinks' => 'interwiki links removed',
    'changed_sitelinks' => 'interwiki links updated',
    'added_lemmas' => 'lemmas added',
    'removed_lemmas' => 'lemmas removed',
    'changed_lemmas' => 'lemmas changed',
    'added_forms' => 'forms added',
    'removed_forms' => 'forms removed',
    'changed_forms' => 'forms changed',
    'added_senses' => 'senses added',
    'removed_senses' => 'senses removed',
    'changed_senses' => 'senses changed',
    'create_property' => 'properties created',
    'create_lexeme' => 'lexeme items created',
    'added_representations' => 'representations added',
    'removed_representations' => 'representations removed',
    'changed_representations' => 'representations changed',
    'added_glosses' => 'glosses added',
    'removed_glosses' => 'glosses removed',
    'changed_glosses' => 'glosses changed',
    'added_formclaims' => 'form claims added',
    'removed_formclaims' => 'form claims removed',
    'changed_formclaims' => 'form claims changed',
    'added_senseclaims' => 'sense claims added',
    'removed_senseclaims' => 'sense claims removed',
    'changed_senseclaims' => 'sense claims changed'
  }.freeze

  def initialize(course)
    @course = course
  end

  # Updates the summary field of each revision with its wikidata diff stats,
  # and marks revisions as `deleted` when the analyzer couldn't retrieve their
  # content (suppressed/missing/deleted) — this replaces Lift Wing as the
  # source of truth for deletion detection on Wikidata. Scoped revisions get
  # the full diff; non-scoped revisions admit only merge_to into an in-scope
  # target (see issue #6813).
  def update_revisions_with_stats(revisions)
    result = analyze_revisions(revisions.map(&:mw_rev_id))
    not_analyzed = result[:diffs_not_analyzed].to_set
    revisions.each { |rev| apply_diff(rev, result[:diffs], not_analyzed) }
    revisions
  rescue WikidataDiffAnalyzerError
    revisions.each { |rev| rev.error = true }
    revisions
  end

  # Given an array of revisions, it builds the stats for those revisions
  def build_stats_from_revisions(revisions)
    stats = STATS_CLASSIFICATION.values.to_h { |label| [label, 0] }
    revisions.each do |revision|
      revision.diff_stats&.each do |key, value|
        # Skip non-counter fields the analyzer may include (e.g. merge_target).
        ui_label = STATS_CLASSIFICATION[key] or next
        stats[ui_label] += value
      end
    end
    stats['total revisions'] = revisions.count
    stats
  end

  # Given an array of indivual stats, it creates or updates the CourseStats row for it.
  def update_wikidata_statistics(individual_stats)
    stats = sum_up_stats individual_stats
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)

    # Update the stats_hash in the CourseStat model and save it
    crs_stat.stats_hash[wikidata.domain] = stats
    crs_stat.save
  end

  private

  def apply_diff(revision, diffs, not_analyzed)
    if not_analyzed.include?(revision.mw_rev_id)
      revision.deleted = true
      return
    end
    diff = diffs[revision.mw_rev_id]
    if revision.scoped
      revision.summary = diff.to_json
    elsif merge_into_in_scope_target?(diff)
      revision.summary = { 'merge_to' => 1 }.to_json
    end
  end

  # Admit a non-scoped revision's merge_to contribution iff the merge target
  # parsed from the edit comment is itself a scoped article on this course.
  def merge_into_in_scope_target?(diff)
    return false unless diff && diff[:merge_to] == 1
    target = diff[:merge_target]
    return false unless target
    @course.scoped_article?(wikidata, target, nil)
  end

  TYPICAL_ERRORS = [].freeze

  RETRY_COUNT = 3

  def analyze_revisions(revision_ids)
    tries ||= RETRY_COUNT
    WikidataDiffAnalyzer.analyze(revision_ids)
  rescue StandardError => e
    tries -= 1
    retry unless tries.zero?
    log_error(e, sentry_extra: { revision_ids: })
    raise WikidataDiffAnalyzerError
  end

  def sum_up_stats(individual_stats)
    total_stats = STATS_CLASSIFICATION.values.to_h { |label| [label, 0] }
    total_stats['total revisions'] = 0
    individual_stats.each do |hash|
      hash.each { |key, value| total_stats[key] += value }
    end
    total_stats
  end

  def wikidata
    Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  class WikidataDiffAnalyzerError < StandardError; end
end
