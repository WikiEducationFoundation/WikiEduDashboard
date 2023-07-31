# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/wikidata_summary_parser"
require_dependency "#{Rails.root}/lib/importers/wikidata_summary_importer"
# require the installed wikidata-diff-analyzer gem
require 'wikidata-diff-analyzer'

class UpdateWikidataStats
  def initialize(course)
    @course = course
    #import_summaries
    update_summary_with_stats
    update_wikidata_statistics
  end

  private

  # When summary is nil, instead of fetching edit summaries for each revision, I want to use
  # wikidata-diff-analyzer to get the stats saved in the database after serializing.
  # That means while UpdateWikidataStats will be called for a course, all the revisions which
  # had edit summaries in the summary field be processed with WikidataSummaryParser
  # if summary is nil, then the stats would be saved in the summary

  def update_summary_with_stats
    return if wikidata_revisions_without_summaries.empty?
    revision_ids = wikidata_revisions_without_summaries.pluck(:mw_rev_id)
    analyzed_revisions = WikidataDiffAnalyzer.analyze(revision_ids)[:diffs]
    revision_ids.each do |rev_id|
      individual_stat = analyzed_revisions[rev_id]
      # Serialize the individual_stat to JSON format
      serialized_stat = individual_stat.to_json

      # Find the revision object by mw_rev_id
      revision = course_revisions.find_by(mw_rev_id: rev_id)

      # Update the summary field with the serialized_stat
      revision.update(summary: serialized_stat)
    end
  end
  def import_summaries
    return if wikidata_revisions_without_summaries.empty?
    WikidataSummaryImporter.new.import_missing_summaries wikidata_revisions_without_summaries
  end

  # Get Wikidata stats based on revision's summaries

  def update_wikidata_statistics
    return if course_revisions.empty?
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
    # crs_stat.stats_hash[wikidata.domain] = stats
    # crs_stat.save
    stats_hash = crs_stat.stats_hash || {}

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
    stats_hash = merge_stats(summary_stats, serialized_stats)
    # Update the stats_hash in the CourseStat model and save it
    crs_stat.stats_hash = stats_hash
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
    # Initialize a hash with the same order of attributes like they exist in the serialized stats
    strings = ['claims created', 'claims removed', 'claims changed', 'references added', 'references removed', 'references changed', 'qualifiers added', 'qualifiers removed', 'qualifiers changed', 'aliases added', 'aliases removed', 'aliases changed', 'labels added', 'labels removed', 'labels changed', 'descriptions added', 'descriptions removed', 'descriptions changed', 'interwiki links added', 'interwiki links removed', 'interwiki links updated', 'merged to', 'merged from', 'redirects created', 'reverts performed', 'restorations performed', 'items cleared', 'items created', 'lemmas added', 'lemmas removed', 'lemmas changed', 'forms added', 'forms removed', 'forms changed', 'senses added', 'senses removed', 'senses changed', 'properties created', 'lexeme items created', 'representations added', 'representations removed', 'representations changed', 'glosses added', 'glosses removed', 'glosses changed', 'form claims added', 'form claims removed', 'form claims changed', 'sense claims added', 'sense claims removed', 'sense claims changed']
    stats = Hash[strings.map { |string| [string, 0] }]

    # create a sum of stats after deserilizing the stats for each revision object
    revisions_with_serialized_stats.each do |revision|
      # Deserialize the summary field to get the stats
      deserialized_stat = revision.diff_stats
      # create a stats which sums up each field of the deserialized_stat and create a stats hash
      deserialized_stat.each_with_index do |(key, value), index|
        stats[strings[index]] += value
      end
    end
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
