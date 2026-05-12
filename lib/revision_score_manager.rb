# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/lift_wing_api"

# Handles fetching and scoring article revisions for course-specific graphs.
class RevisionScoreManager
  def initialize(article, course)
    @article = article
    @course = course
    @wiki = article.wiki
  end

  MAX_REVISION_COUNT = 50

  def fetch_scored_revisions(enrolled_usernames)
    revisions = get_student_revisions(enrolled_usernames)
    return [] if revisions.empty?
    cached_scored_revisions(revisions.first(MAX_REVISION_COUNT))
  end

  private

  # Use the ID of the most recent revision as the cache key
  # If this ID changes, the cache automatically invalidates.
  def cache_key(recent_revision_id)
    "article_#{@course.id}_#{@article.mw_page_id}_#{recent_revision_id}"
  end

  # Caches scored revisions to avoid hitting LiftWing API repeatedly for the same data
  def cached_scored_revisions(target_revisions)
    Rails.cache.fetch(cache_key(target_revisions.first[:revid]), expires_in: 1.day) do
      rev_ids = target_revisions.map { |r| r[:revid] }
      scores = score_revisions(rev_ids)

      target_revisions.map do |rev|
        {
          rev_id: rev[:revid],
          characters: rev[:size],
          wp10: scores.dig(rev[:revid].to_s, 'wp10'),
          date: rev[:timestamp],
          username: rev[:user]
        }
      end
    end
  end

  # Filters the total revision to a manageable number for plotting.
  # We explicitly take the most recent revisions (up to MAX_REVISION_COUNT)
  # to ensure the graph remains performant and readable.
  def get_student_revisions(enrolled_usernames)
    params = query_params
    student_revisions = []

    loop do
      response = WikiApi.new(@wiki).query(params)
      page_data = response['query']['pages'][@article.mw_page_id.to_s]

      process_revisions(page_data['revisions'], enrolled_usernames, student_revisions)

      # Exits loop if there is no continue parameter in response or
      # Stop immediately if we found 50 student revisions
      break if student_revisions.size >= MAX_REVISION_COUNT || !response['continue']

      # When the API returns a continue hash, pull out its
      # `rvcontinue`/`continue` tokens and merge them into `params`.
      # That mutates the query parameters so the next loop iteration
      # will request the next page of revisions.
      params.merge!(response['continue'].slice('rvcontinue', 'continue'))
    end
    student_revisions
  end

  def process_revisions(revisions, usernames, results)
    (revisions || []).each do |r|
      next unless usernames.include?(r['user'])

      results << {
        revid: r['revid'],
        user: r['user'],
        timestamp: r['timestamp'],
        size: r['size']
      }
    end
  end

  def score_revisions(rev_ids)
    LiftWingApi.new(@wiki).get_revision_data(rev_ids)
  end

  # Queries for revisions made within the course period
  # [course.start, course.end]
  def query_params
    {
      action: 'query',
      prop: 'revisions',
      pageids: @article.mw_page_id,
      rvprop: 'user|ids|timestamp|size',
      rvstart: @course.end.strftime('%Y%m%d%H%M%S'),
      rvend: @course.start.strftime('%Y%m%d%H%M%S'),
      rvdir: 'older', # List newest first. rvstart has to be later than rvend.
      rvlimit: 500
    }
  end
end
