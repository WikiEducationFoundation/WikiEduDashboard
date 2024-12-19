# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/wikidata_summary_parser"
require_dependency "#{Rails.root}/lib/importers/wikidata_summary_importer"
# require the installed wikidata-diff-analyzer gem
require 'wikidata-diff-analyzer'

class UpdateWikidataStatsTimeslice
  # This hash contains the keys of the wikidata-diff-analyzer output hash
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
  end

  # Given an array of revisions, it updates the summary field for each one with
  # the wikidata stats. wikidata-diff-analyzer gem is used to fetch the stats.
  # Returns the updated array.
  def update_revisions_with_stats(revisions)
    revision_ids = revisions.pluck(:mw_rev_id)
    analyzed_revisions = WikidataDiffAnalyzer.analyze(revision_ids)[:diffs]
    revisions.each do |revision|
      rev_id = revision.mw_rev_id
      individual_stat = analyzed_revisions[rev_id]
      serialized_stat = individual_stat.to_json
      revision.summary = serialized_stat
    end
    revisions
  end

  # Given an array of revisions, it builds the stats for those revisions
  def build_stats_from_revisions(revisions)
    stats = {}
    STATS_CLASSIFICATION.each_key do |key|
      stats[STATS_CLASSIFICATION[key]] = 0
    end

    # create a sum of stats after deserializing the stats for each revision object
    revisions.each do |revision|
      # Deserialize the summary field to get the stats
      deserialized_stat = summary(revision)
      next if deserialized_stat.nil?
      # create a stats which sums up each field of the deserialized_stat and create a stats hash
      deserialized_stat.each do |key, value|
        stats[STATS_CLASSIFICATION[key]] += value
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

  def sum_up_stats(individual_stats)
    total_stats = {}
    STATS_CLASSIFICATION.each_key do |key|
      total_stats[STATS_CLASSIFICATION[key]] = 0
    end
    # Add total revisions
    total_stats['total revisions'] = 0

    # Iterate over each individual stat and sum up the values
    individual_stats.each do |hash|
      hash.each do |key, value|
        total_stats[key] += value
      end
    end
    total_stats
  end

  def wikidata
    Wiki.get_or_create(language: nil, project: 'wikidata')
  end

  # This function parses the serialized stats saved in the summary field, in case of any errors
  # it returns nil meaning the field contains an edit summary
  def summary(revision)
    summary = revision.summary
    JSON.parse(summary) if summary.present? && summary.start_with?('{', '[')
  rescue JSON::ParserError
    nil # Return nil if parsing fails (i.e., not diff_stats)
  end
end
