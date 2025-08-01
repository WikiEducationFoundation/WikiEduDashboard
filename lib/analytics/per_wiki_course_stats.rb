# frozen_string_literal: true

class PerWikiCourseStats
  def initialize(course, namespace)
    @course = course
    @wikis = @course.wikis
    @namespace = namespace
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
      "#{wiki.domain}_edits" => @course.scoped_article_timeslices
                                       .where(tracked: true)
                                       .joins(:article)
                                       .where(articles: { wiki: })
                                       .sum(&:revision_count),
      "#{wiki.domain}_articles_edited" => @course.articles.where(wiki:,
                                                                 namespace: @namespace).count,
      "#{wiki.domain}_articles_created" => @course.new_articles_on(wiki).count
    }
  end
end
