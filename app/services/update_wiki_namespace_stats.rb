# frozen_string_literal: true

class UpdateWikiNamespaceStats
  def self.clear_untracked_namespace_data(course)
    tracked_keys = stat_keys(course.course_wiki_namespaces)
    course_stats = CourseStat.find_or_create_by(course_id: course.id)
    course_stats.stats_hash.each_key do |key|
      next unless key.include?('-namespace-') # only clear namespace data, not wikidata stats, etc.
      next if tracked_keys.include?(key)
      course_stats.stats_hash.delete(key)
    end
    course_stats.save
  end

  def self.stat_keys(course_wiki_namespaces)
    course_wiki_namespaces.map do |course_wiki_ns|
      stat_key(course_wiki_ns.courses_wikis.wiki, course_wiki_ns.namespace)
    end
  end

  def self.stat_key(wiki, namespace)
    "#{wiki.domain}-namespace-#{namespace}"
  end

  def initialize(course, wiki, namespace)
    @course = course
    @wiki = wiki
    @namespace = namespace
    update_stats
  end

  def update_stats
    stats = {
      edited_count: edited_articles_count,
      new_count: new_articles_count,
      revision_count:,
      user_count:,
      word_count:,
      reference_count:,
      view_count:
    }
    course_stats = CourseStat.find_or_create_by(course_id: @course.id)
    course_stats.stats_hash[UpdateWikiNamespaceStats.stat_key(@wiki, @namespace)] = stats
    course_stats.save
  end

  private

  # live, tracked articles filtered by wiki and namespace
  def articles_filtered_by_wiki_namespace
    # do not use tracked and live scopes to avoid issue #5911
    @course.articles_courses.joins(:article).where(articles: { wiki: @wiki, namespace: @namespace,
           deleted: false }).where(tracked: true)
  end

  def edited_articles_count
    articles = articles_filtered_by_wiki_namespace
    articles.count
  end

  def new_articles_count
    articles = articles_filtered_by_wiki_namespace
    articles.new_article.count
  end

  def revision_count
    articles_filtered_by_wiki_namespace.sum(:revision_count)
  end

  def user_count
    articles_filtered_by_wiki_namespace.sum([], &:user_ids).uniq.count
  end

  def word_count
    character_sum = articles_filtered_by_wiki_namespace.sum(:character_sum)
    WordCount.from_characters(character_sum)
  end

  def reference_count
    articles_filtered_by_wiki_namespace.sum(:references_count)
  end

  def view_count
    articles = articles_filtered_by_wiki_namespace
    articles.sum(:view_count)
  end
end
