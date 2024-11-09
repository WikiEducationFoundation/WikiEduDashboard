# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/wikidata_summary_parser"
require_dependency "#{Rails.root}/lib/importers/wikidata_summary_importer"
# require the installed wikidata-diff-analyzer gem
require 'wikidata-diff-analyzer'

class UpdateWikidataStats
  # This hash contains uses the keys of the wikidata-diff-analyzer output hash
  # and maps them to the values used in the UI and CourseStat Hash
  STATS_CLASSIFICATION = {
    # UI section: General
    'merge_to' => 'merged to',
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
    'merge_from' => 'merged from',
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
    update_summary_with_stats
    update_wikidata_statistics
  end

  private

  # When summary is nil, instead of fetching edit summaries for each revision
  # wikidata-diff-analyzer gem is used to get the stats saved in the database after serializing.
  # That means while UpdateWikidataStats will be called for a course, all the revisions which
  # had edit summaries in the summary field be processed with WikidataSummaryParser
  # and the revisions which didn't have edit summaries will be processed
  # with wikidata-diff-analyzer gem.
  # if summary is nil, then the stats would be created and saved in the summary

  def update_summary_with_stats
    return if wikidata_revisions_without_summaries.empty?
    revision_ids = wikidata_revisions_without_summaries.pluck(:mw_rev_id)

    # Analyze the revisions, wrapped in a begin-rescue to handle errors from WikidataDiffAnalyzer.
    # This is a temporary workaround to prevent the gem errors from breaking processing.
    analyzed_revisions = {}
    analyzed_revisions = WikidataDiffAnalyzer.analyze(revision_ids)[:diffs] rescue (
    # Log the error for debugging, but allow the method to continue
    Rails.logger.error("WikidataDiffAnalyzer failed: #{$!.message}"))

    Revision.transaction do
      wikidata_revisions_without_summaries.each do |revision|
        rev_id = revision.mw_rev_id

        # Skip this revision if no analyzed revision available for the current rev_id.
        # This ensures only revisions that were successfully analyzed are processed.
        next unless analyzed_revisions[rev_id]

        individual_stat = analyzed_revisions[rev_id]
        serialized_stat = individual_stat.to_json
        revision.summary = serialized_stat
        revision.save!
      end
    end
  end

  def update_wikidata_statistics
    return if course_revisions.empty?

    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)

    # Initialize arrays to store revisions with edit summaries and serialized stats
    revisions_with_summary = []
    revisions_with_serialized_stats = []

    # Divide revisions based on edit summaries or serialized stats
    course_revisions.each do |revision|
      if revision.edit_summary
        revisions_with_summary << revision
      else
        # If the summary contains an edit summary, add it to the revisions_with_summary array
        revisions_with_serialized_stats << revision
      end
    end

    summary_stats = WikidataSummaryParser.analyze_revisions(revisions_with_summary)
    serialized_stats = get_stats_from_serialized_stats(revisions_with_serialized_stats)
    stats = merge_stats(summary_stats, serialized_stats)
    # Update the stats_hash in the CourseStat model and save it
    crs_stat.stats_hash[wikidata.domain] = stats
    crs_stat.save
  end

  def merge_stats(summary_stats, serialized_stats)
    # Create a set of all unique keys from both 'summary_stats' and 'serialized_stats'
    all_keys = summary_stats.keys.concat(serialized_stats.keys).uniq

    # Initialize a new hash to store the merged stats
    merged_stats = {}

    # Iterate through all unique keys and add the values from 'summary_stats' and 'serialized_stats'
    all_keys.each do |key|
      summary_value = summary_stats[key].to_i # gracefully handle nil values
      serialized_value = serialized_stats[key].to_i
      merged_stats[key] = summary_value + serialized_value
    end

    merged_stats
  end

  def get_stats_from_serialized_stats(revisions_with_serialized_stats)
    stats = {}
    STATS_CLASSIFICATION.each_key do |key|
      stats[STATS_CLASSIFICATION[key]] = 0
    end

    # create a sum of stats after deserializing the stats for each revision object
    revisions_with_serialized_stats.each do |revision|
      # Deserialize the summary field to get the stats
      deserialized_stat = revision.diff_stats

      # Skip processing if deserialized_stat is nil or false
      # This ensures invalid or missing stats are not summed
      next unless deserialized_stat

      # create a stats which sums up each field of the deserialized_stat and create a stats hash
      deserialized_stat.each do |key, value|
        stats[STATS_CLASSIFICATION[key]] += value
      end
    end
    stats['total revisions'] = revisions_with_serialized_stats.count
    stats
  end

  def wikidata_revisions_without_summaries
    course_revisions.where(summary: nil)
  end

  def course_revisions
    @course.revisions.where(wiki: wikidata, deleted: false)
  end

  def wikidata
    @wikidata ||= Wiki.get_or_create(language: nil, project: 'wikidata')
  end
end
