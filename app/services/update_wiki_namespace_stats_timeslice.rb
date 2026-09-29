# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/word_count"

# Updates the stats of every tracked wiki namespace of a course, and removes the
# stats of namespaces that are no longer tracked. Stats are aggregated grouped by
# wiki and namespace, so the number of queries does not grow with tracked namespaces.
class UpdateWikiNamespaceStatsTimeslice
  EMPTY_ARTICLES_STATS = { edited_count: 0, new_count: 0, character_sum: 0,
                           reference_count: 0, view_count: 0 }.freeze

  def initialize(course)
    @course = course
    @wiki_namespaces = course.course_wiki_namespaces.includes(courses_wikis: :wiki)
                             .map { |cwn| [cwn.courses_wikis.wiki, cwn.namespace] }
    update_stats
  end

  private

  def update_stats
    course_stats = CourseStat.find_or_create_by(course_id: @course.id)
    clear_untracked_namespace_data(course_stats.stats_hash)
    articles_stats = articles_courses_stats
    revision_counts = revision_counts_by_namespace
    user_counts = user_counts_by_namespace
    @wiki_namespaces.each do |wiki, namespace|
      group = [wiki.id, namespace]
      course_stats.stats_hash[stat_key(wiki, namespace)] =
        namespace_stats(wiki, articles_stats.fetch(group, EMPTY_ARTICLES_STATS),
                        revision_counts.fetch(group, 0), user_counts.fetch(group, 0))
    end
    course_stats.save
  end

  # Remove stats data for any namespaces that were previously
  # tracked but are no longer tracked.
  def clear_untracked_namespace_data(stats_hash)
    tracked_keys = @wiki_namespaces.map { |wiki, namespace| stat_key(wiki, namespace) }
    stats_hash.delete_if do |key, _stats|
      # only clear namespace data, not wikidata stats, etc.
      key.include?('-namespace-') && !tracked_keys.include?(key)
    end
  end

  def stat_key(wiki, namespace)
    "#{wiki.domain}-namespace-#{namespace}"
  end

  def namespace_stats(wiki, articles_stats, revision_count, user_count)
    # compact drops word_count on wikis where byte counts are not prose.
    {
      edited_count: articles_stats[:edited_count],
      new_count: articles_stats[:new_count],
      revision_count:,
      user_count:,
      word_count: word_count(wiki, articles_stats[:character_sum]),
      reference_count: articles_stats[:reference_count],
      view_count: articles_stats[:view_count]
    }.compact
  end

  # Byte counts on excluded wikis are not prose, so no word count is reported for
  # their namespaces at all; extrapolating one from a Wikidata entity diff would
  # be misleading. See WordCount::EXCLUDED_PROJECTS.
  def word_count(wiki, character_sum)
    return if WordCount::EXCLUDED_PROJECTS.include?(wiki.project)
    WordCount.from_characters(character_sum)
  end

  # live articles in the tracked wikis and namespaces
  def articles_filter
    { wiki_id: @wiki_namespaces.map { |wiki, _namespace| wiki.id }.uniq,
      namespace: @wiki_namespaces.map(&:last).uniq,
      deleted: false }
  end

  # live, tracked articles in the tracked wikis and namespaces
  def tracked_articles_courses
    # do not use tracked and live scopes to avoid issue #5911
    @course.articles_courses.joins(:article).where(articles: articles_filter)
           .where(tracked: true)
  end

  # Returns { [wiki_id, namespace] => articles stats }
  def articles_courses_stats
    tracked_articles_courses
      .group('articles.wiki_id', 'articles.namespace')
      .pluck('articles.wiki_id', 'articles.namespace', 'COUNT(articles_courses.id)',
             'SUM(articles_courses.new_article)', 'SUM(articles_courses.character_sum)',
             'SUM(articles_courses.references_count)', 'SUM(articles_courses.view_count)')
      .to_h do |wiki_id, namespace, edited, new_count, characters, references, views|
        [[wiki_id, namespace],
         { edited_count: edited, new_count: new_count.to_i, character_sum: characters.to_i,
           reference_count: references.to_i, view_count: views.to_i }]
      end
  end

  # Returns { [wiki_id, namespace] => revision count }. Computed using timeslices,
  # since ArticlesCourses records do not have a revision_count field.
  def revision_counts_by_namespace
    @course.article_course_timeslices
           .joins(:article).where(articles: articles_filter)
           .where(article_id: tracked_articles_courses.select(:article_id))
           .group('articles.wiki_id', 'articles.namespace')
           .sum('article_course_timeslices.revision_count')
  end

  # Returns { [wiki_id, namespace] => user count }.
  # user_ids is a serialized array, so it cannot be aggregated in SQL.
  def user_counts_by_namespace
    tracked_articles_courses
      .pluck('articles.wiki_id', 'articles.namespace', :user_ids)
      .group_by { |wiki_id, namespace, _user_ids| [wiki_id, namespace] }
      .transform_values { |rows| rows.flat_map(&:last).uniq.count }
  end
end
