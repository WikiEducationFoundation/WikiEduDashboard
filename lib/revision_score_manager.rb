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
  
  def fetch_scored_revisions(enrolled_usernames) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    # Fetch all revisions from Wiki API
    # Within course start and end date
    revisions = get_revision_ids
    
    # Filter for only the students in this course
    user_revisions = revisions.select { |rev| enrolled_usernames.include?(rev[:user]) }
    return [] if user_revisions.empty?

    target_revisions = relevant_revisions(user_revisions)
    
    # Use the ID of the most recent revision in the set as the cache key
    # If this ID changes, the cache automatically invalidates.
    cache_key = "article_#{@course.id}_#{@article.mw_page_id}_#{target_revisions.first[:revid]}"

    Rails.cache.fetch(cache_key, expires_in: 1.day) do 
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


  def relevant_revisions(revisions)
    within_revision_limit? ? revisions : revisions.first(MAX_REVISION_COUNT)
  end
  
  # Returns true if the revision count is within a performant range.
  def within_revision_limit?
    count = ArticleCourseTimeslice.where(article_id: @article.id, course_id: @course.id)
                                  .sum(:revision_count)
    count <= MAX_REVISION_COUNT
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
      # Stop if we hit our manual limit or there is no more data
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
