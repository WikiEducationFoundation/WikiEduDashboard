# frozen_string_literal: true

#= Service for updating the counts that are cached on ArticlesCourses objects
class ArticlesCoursesCacheManager
  BATCH_SIZE = 1000
  UPDATED_FIELDS = %i[character_sum references_count user_ids new_article
                      first_revision updated_at].freeze
  # Values for an articles_courses record whose timeslices are all gone.
  EMPTY_CACHE = { character_sum: 0, references_count: 0, user_ids: [],
                  new_article: false, first_revision: nil }.freeze

  def initialize(articles_courses)
    @articles_courses = articles_courses
  end

  # Recalculates the cached fields from the article course timeslices, aggregating
  # them in SQL and writing every record of a batch with a single upsert.
  def update_caches_from_timeslices
    @articles_courses.pluck(:id, :course_id, :article_id)
                     .each_slice(BATCH_SIZE) { |batch| write_caches(batch) }
  end

  private

  # Takes [id, course_id, article_id] triples and writes their recalculated caches.
  def write_caches(records)
    stats = timeslice_stats(records)
    now = Time.zone.now
    rows = records.map do |id, course_id, article_id|
      { id:, course_id:, article_id:, updated_at: now,
        **(stats[[course_id, article_id]] || EMPTY_CACHE) }
    end
    ArticlesCourses.upsert_all(rows, update_only: UPDATED_FIELDS)
  end

  # Returns { [course_id, article_id] => cache values }. Timeslices are queried per
  # course so that the article_course_timeslices unique index applies.
  def timeslice_stats(records)
    stats = {}
    records.group_by { |_id, course_id, _article_id| course_id }
           .each do |course_id, triples|
      stats.merge!(stats_for_course(course_id, triples.map(&:last)))
    end
    stats
  end

  def stats_for_course(course_id, article_ids)
    timeslices = ArticleCourseTimeslice.where(course_id:, article_id: article_ids)
    stats = aggregated_stats(timeslices)
    user_ids_by_article(timeslices).each { |id, user_ids| stats[id][:user_ids] = user_ids }
    stats.transform_keys { |article_id| [course_id, article_id] }
  end

  # SQL aggregates for every cached field but user_ids, keyed by article id.
  def aggregated_stats(timeslices)
    timeslices.group(:article_id)
              .pluck(:article_id, 'SUM(character_sum)', 'SUM(references_count)',
                     'MAX(new_article)', 'MIN(first_revision)')
              .to_h do |article_id, chars, refs, new_article, first_revision|
                [article_id,
                 { character_sum: chars.to_i, references_count: refs.to_i,
                   new_article: new_article.to_i.positive?, first_revision:,
                   user_ids: [] }]
              end
  end

  # user_ids is a serialized array, so it cannot be aggregated in SQL.
  def user_ids_by_article(timeslices)
    timeslices.pluck(:article_id, :user_ids)
              .group_by(&:first)
              .transform_values { |pairs| pairs.flat_map(&:last).uniq }
  end
end
