# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/lift_wing_api"

# Handles fetching and scoring article revisions for course-specific graphs.
class RevisionScoreManager
  def initialize(article, course)
    @article = article
    @course = course
    @wiki = article.wiki
  end

  MAX_REVISION_COUNT = 100

  # Returns every revision in the course period (most recent first, capped at
  # MAX_REVISION_COUNT), each scored with wp10. Editor role classification is
  # left to the frontend, which already has the course users in its store.
  def fetch_scored_revisions
    revisions = get_revisions
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

  # Collects every revision in the course period, most recent first, up to
  # MAX_REVISION_COUNT, paging through the API as needed.
  def get_revisions
    params = query_params
    revisions = []

    loop do
      response = WikiApi.new(@wiki).query(params)
      page_data = response['query']['pages'][@article.mw_page_id.to_s]

      collect_revisions(page_data['revisions'], revisions)

      break if revisions.size >= MAX_REVISION_COUNT || !response['continue']

      # Merge the API's continue tokens into params so the next iteration
      # requests the following page of revisions.
      params.merge!(response['continue'].slice('rvcontinue', 'continue'))
    end
    revisions
  end

  def collect_revisions(revisions, results)
    (revisions || []).each do |r|
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
