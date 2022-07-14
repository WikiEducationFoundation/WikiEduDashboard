# frozen_string_literal: true

class UpdateNamespaceStats

  def initialize(course)
    @course = course
    update_stats
  end

  def update_stats
    wiki_namespaces = @course.tracked_namespaces
    stats = {}

    wiki_namespaces.each do |wiki_ns|
      @wiki = wiki(wiki_ns[:wiki])
      namespaces = wiki_ns[:namespaces]
      wiki_stats = {}
      namespaces.each do |ns|
        @namespace = ns
        wiki_stats[@namespace] = {
          'edited_count': edited_articles_count,
          'new_count': new_articles_count,
          'revision_count': revision_count,
          'user_count': user_count,
          'word_count': word_count,
          'references_count': references_count,
          'views_count': views_count
        }
      end
      stats[@wiki.domain] = wiki_stats
    end
    
    crs_stat = CourseStat.find_by(course_id: @course.id) || CourseStat.create(course_id: @course.id)
    crs_stat.stats_hash['namespace_stats'] = {}
    stats.each do |k, v|
      crs_stat.stats_hash['namespace_stats'][k] = v
    end
    crs_stat.save
  end

  def wiki(wiki)
    language = Wiki.language_for_multilingual(language: wiki[:language], project: wiki[:project])
    Wiki.find_by(language: language, project: wiki[:project])
  end

  def live_revisions
    @course.revisions.where.not(article_id: @course.articles_courses.not_tracked.pluck(:article_id))
             .where(wiki_id: @wiki.id)
             .namespace(@namespace).live
  end

  def edited_articles_count
    @course.articles_courses.joins(:article).where(articles: { wiki: @wiki, namespace: @namespace })
                                            .tracked.live.count
	end

  def new_articles_count
    @course.articles_courses.joins(:article).where(articles: { wiki: @wiki, namespace: @namespace })
                                            .tracked.live.new_article.count
  end

  def revision_count
    revisions = live_revisions
    revisions.size
  end

  def user_count
    revisions = live_revisions
    revisions.distinct.pluck(:user_id).count
  end

  def word_count
    revisions = live_revisions
    character_sum = revisions.where('characters >= 0').sum(:characters) || 0
    WordCount.from_characters(character_sum)
  end

  def references_count
    revisions = live_revisions
    revisions.sum(&:references_added)
  end

  def views_count
    @course.articles_courses.joins(:article).where(articles: { wiki: @wiki, namespace: @namespace })
                                            .tracked.live.sum(:view_count)
  end

end