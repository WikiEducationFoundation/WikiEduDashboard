# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wikidata_summary_parser"

class UpdateWikidataStats
  def initialize(course)
    @course = course
    update_summaries
    update_wikidata_stats
  end

  private

  def update_summaries
    return if wikidata_revisions.empty?
    wikidata_revisions.find_in_batches do |rev_batch|
      rev_batch.each do |rev|
        summary = WikidataSummaryParser.fetch_summary(rev)
        next if summary.nil?
        begin
          rev.update!(summary: summary)
        rescue ActiveRecord::StatementInvalid => e
          Sentry.capture_exception e
          rev.update(summary: CGI.escape(summary))
        end
      end
    end
  end

  # Get Wikidata stats based on revision's summaries

  def update_wikidata_stats
    return if course_revisions.empty?
    stats = WikidataSummaryParser.analyze_revisions(course_revisions)
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
    crs_stat.stats_hash = stats
    crs_stat.save
  end

  def wikidata_revisions
    @course.revisions.where(wiki: wikidata, summary: nil, deleted: false)
  end

  def course_revisions
    @course.revisions.where(wiki: wikidata, deleted: false)
  end

  def wikidata
    Wiki.get_or_create(language: nil, project: 'wikidata')
  end
end
