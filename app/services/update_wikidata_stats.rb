# frozen_string_literal: true

require_dependency Rails.root.join('lib/wikidata_summary_parser')
require_dependency Rails.root.join('lib/importers/wikidata_summary_importer')

class UpdateWikidataStats
  def initialize(course)
    @course = course
    import_summaries
    update_wikidata_statistics
  end

  private

  def import_summaries
    return if wikidata_revisions_without_summaries.empty?
    WikidataSummaryImporter.new.import_missing_summaries wikidata_revisions_without_summaries
  end

  # Get Wikidata stats based on revision's summaries

  def update_wikidata_statistics
    return if course_revisions.empty?
    stats = WikidataSummaryParser.analyze_revisions(course_revisions)
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
    crs_stat.stats_hash[wikidata.domain] = stats
    crs_stat.save
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
