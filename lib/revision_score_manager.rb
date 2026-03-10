# frozen_string_literal: true
require_dependency "#{Rails.root}/lib/lift_wing_api"

class RevisionScoreManager
  # Handles fetching and scoring article revisions for course-specific graphs.
  def initialize(article, course)
    @article = article
    @course = course
    @wiki = article.wiki
  end

  def fetch_scored_revisions(enrolled_usernames)
    revisions = get_revision_ids
    # Filter only revisions made by enrolled users
    relevant_revisions = revisions.select { |rev| enrolled_usernames.include?(rev[:user]) }
    return [] if relevant_revisions.empty?

    rev_ids = relevant_revisions.map { |r| r[:revid] }
    scores = score_revisions(rev_ids)

    relevant_revisions.map do |rev|
      {
        rev_id: rev[:revid],
        characters: rev[:size],
        wp10: scores.dig(rev[:revid].to_s, 'wp10'),
        date: rev[:timestamp],
        username: rev[:user]
      }
    end
  end

  # Returns true if the revision count is within a performant range.
  def within_revision_limit?
    article_course = ArticlesCourses.find_by(article_id: @article.id, course_id: @course.id)

    # If no record exists, we allow the request (default to true)
    return true if article_course.nil?
    
    count = article_course.try(:revision_count) || 0
    count < 500
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
      break unless response['continue']
      # When the API returns a continue hash, pull out its
      # `rvcontinue`/`continue` tokens and merge them into `params`.
      # That mutates the query parameters so the next loop iteration
      # will request the next page of revisions.
      params.merge!(response['continue'].slice('rvcontinue', 'continue'))
    end
    puts "In last #{revisions.inspect}"
    revisions
  end

  def score_revisions(rev_ids)
    LiftWingApi.new(@wiki).get_revision_data(rev_ids)
  end

  def query_params
    {
      action: 'query',
      prop: 'revisions',
      pageids: @article.mw_page_id,
      rvprop: 'user|ids|timestamp|size',
      rvlimit: 500,
      rvstart: @course.end.strftime('%Y%m%d%H%M%S'),
      rvend: @course.start.strftime('%Y%m%d%H%M%S')
    }
  end
end
