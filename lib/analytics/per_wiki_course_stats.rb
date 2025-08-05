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
      "#{wiki.domain}_edits" => @course.scoped_article_timeslices
                                       .where(tracked: true)
                                       .joins(:article)
                                       .where(articles: { wiki: })
                                       .sum(&:revision_count),
      "#{wiki.domain}_articles_edited" => @course.articles.where(wiki:).count,
      "#{wiki.domain}_articles_created" => ArticlesCourses.joins(:article)
                                                          .where(course_id: 10000, tracked: true, new_article: true) # rubocop:disable Layout/LineLength
                                                          .where(articles: { namespace: @namespace, wiki:, deleted: false }) # rubocop:disable Layout/LineLength
                                                          .count
    }
  end
end
