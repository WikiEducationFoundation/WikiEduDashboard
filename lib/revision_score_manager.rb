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
    # Fetch all revisions from Wiki API
    # Within course start and end date
    revisions = get_revision_ids

    # Filter for only the students in this course
    user_revisions = revisions.select { |rev| enrolled_usernames.include?(rev[:user]) }
    return [] if user_revisions.empty?

    target_revisions = relevant_revisions(user_revisions)

    scored_revisions(target_revisions)

  end

  # Use the ID of the most recent revision as the cache key
  # If this ID changes, the cache automatically invalidates.
  def cache_key(recent_revision_id)
    "article_#{@course.id}_#{@article.mw_page_id}_#{recent_revision_id}"
  end

  # Caches scored revisions to avoid hitting LiftWing API repeatedly for the same data
  def scored_revisions(target_revisions)
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
  def relevant_revisions(revisions)
    revisions.size > MAX_REVISION_COUNT ? revisions.first(MAX_REVISION_COUNT) : revisions
  end

  private

  def get_revision_ids
    params = query_params
    revisions = []
    loop do
      response = WikiApi.new(@wiki).query(params)
      page = response['query']['pages'][@article.mw_page_id.to_s]
      (page['revisions'] || []).each do |r| revisions << { 
              "revid": r['revid'], 
              "user": r['user'], 
              "timestamp": r['timestamp'], 
              "size": r['size']}
      end
      # Exists loop if there is no continue parameter in response
      break if !response['continue']

      # When the API returns a continue hash, pull out its
      # `rvcontinue`/`continue` tokens and merge them into `params`.
      # That mutates the query parameters so the next loop iteration
      # will request the next page of revisions.
      params.merge!(response['continue'].slice('rvcontinue', 'continue'))
    end
     revisions
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
