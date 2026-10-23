# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/csv_edit_counts"

class PerWikiCourseStats
  def initialize(course)
    @course = course
    @wikis = @course.wikis
  end

  def stats
    return @stats unless @stats.nil?
    @stats = {}
    @wikis.each do |wiki|
      @stats.merge! wiki_stats(wiki)
    end
    @stats
  end

  def wiki_stats(wiki)
    {
      "#{wiki.domain}_edits" => edits_by_wiki.fetch(wiki.id, 0),
      "#{wiki.domain}_articles_edited" => @course.articles.where(wiki:).count,
      "#{wiki.domain}_articles_created" => @course.new_articles_on(wiki).count
    }
  end

  private

  def edits_by_wiki
    @edits_by_wiki ||= CsvEditCounts.by_wiki(@course)
  end
end
