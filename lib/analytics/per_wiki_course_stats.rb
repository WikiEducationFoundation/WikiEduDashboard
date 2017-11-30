# frozen_string_literal: true

class PerWikiCourseStats
  def initialize(course)
    @course = course
    @wikis = Wiki.where(id: course.wiki_ids)
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
      "#{wiki.domain}_edits" => @course.revisions.where(wiki: wiki).count,
      "#{wiki.domain}_new_articles" => @course.all_revisions.where(wiki: wiki, new_article: true).count
    }
  end
end
