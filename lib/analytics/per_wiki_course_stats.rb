# frozen_string_literal: true

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
      "#{wiki.domain}_edits" => @course.tracked_revisions.where(wiki:).count,
      "#{wiki.domain}_articles_edited" => @course.articles.where(wiki:).count,
      "#{wiki.domain}_articles_created" => @course.new_articles_on(wiki).count
    }
  end
end
