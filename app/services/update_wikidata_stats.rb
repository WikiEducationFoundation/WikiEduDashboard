# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class UpdateWikidataStats
  def initialize(course)
    @course = course
    import_summaries
    update_wikidata_statistics
  end

  private

  def import_summaries
    return if wikidata_revisions_without_summaries.empty?
    wikidata_revisions_without_summaries.find_in_batches do |rev_batch|
      rev_batch.each do |rev|
        summary = WikidataSummaryParser.fetch_summary(rev)
        next if summary.nil?
        begin
          rev.update!(summary:)
        rescue ActiveRecord::StatementInvalid => e
          Sentry.capture_exception e
          rev.update(summary: CGI.escape(summary))
        end
      end
    end
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
