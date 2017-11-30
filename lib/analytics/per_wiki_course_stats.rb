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
      "#{wiki.domain}_articles_edited" => @course.articles.where(wiki: wiki).count,
      "#{wiki.domain}_articles_created" => @course.new_articles_on(wiki).count
    }
  end
end
