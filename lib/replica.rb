require 'crack'

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   http://tools.wmflabs.org/wikiedudashboard
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  ###################
  # Parsing methods #
  ###################

  # Given a list of users and a start and end date, return a nicely formatted
  # array of revisions made by those users between those dates.
  def get_revisions(users, rev_start, rev_end)
    raw = get_revisions_raw(users, rev_start, rev_end)
    @data = {}
    return @data unless raw.is_a?(Enumerable)
    raw.each { |revision| extract_revision_data(revision) }

    @data
  end

  def extract_revision_data(revision)
    parsed = parse_revision(revision)
    page_id = parsed['article']['mw_page_id']
    unless @data.include?(page_id)
      @data[page_id] = {}
      @data[page_id]['article'] = parsed['article']
      @data[page_id]['revisions'] = []
    end
    @data[page_id]['revisions'].push parsed['revision']
  end

  # Given a single raw json revision, parse it into a more useful format.
  #
  # Example raw revision input:
  #   {
  #     "page_id"=>"418355", "page_title"=>"Babbling", "page_namespace"=>"0",
  #     "rev_id"=>"641327984", "rev_timestamp"=>"20150107003430",
  #     "rev_user_text"=>"Ragesoss", "rev_user"=>"319203",
  #     "new_article"=>"false", "byte_change"=>"121"
  #   }
  #
  # Example parsed revision output:
  #  {
  #     "revision"=>{
  #       "id"=>"641327984", "date"=>Wed, 07 Jan 2015 00:34:30 +0000,
  #       "characters"=>"121", "article_id"=>"418355", "user_id"=>"319203",
  #       "new_article"=>"false"}, "article"=>{"id"=>"418355",
  #       "title"=>"Babbling", "namespace"=>"0"
  #     }
  #   }
  def parse_revision(revision)
    article_data = parse_article_data(revision)
    revision_data = parse_revision_data(revision)

    { 'article' => article_data, 'revision' => revision_data }
  end

  def parse_article_data(revision)
    article_data = {}
    # TODO: decouple id from mw_page_id
    article_data['id'] = revision['page_id']
    article_data['mw_page_id'] = revision['page_id']
    article_data['title'] = revision['page_title']
    article_data['namespace'] = revision['page_namespace']
    article_data['wiki_id'] = @wiki.id
    article_data
  end

  def parse_revision_data(revision)
    revision_data = {}
    # TODO: decouple id from mw_rev_id
    revision_data['id'] = revision['rev_id']
    revision_data['mw_rev_id'] = revision['rev_id']
    revision_data['date'] = revision['rev_timestamp'].to_datetime
    revision_data['characters'] = revision['byte_change']
    # TODO: decouple article_id from mw_page_id
    revision_data['article_id'] = revision['page_id']
    revision_data['mw_page_id'] = revision['page_id']
    revision_data['user_id'] = revision['rev_user']
    revision_data['new_article'] = revision['new_article']
    revision_data['system'] = revision['system']
    revision_data['wiki_id'] = @wiki.id
    revision_data
  end

  ###################
  # Request methods #
  ###################

  # Given a list of users and a start and end date, get data about revisions
  # those users made between those dates.
  # As of 2015-02-24, revisions.php only queries namespaces:
  #   0 ([mainspace])
  #   2 (User:)
  def get_revisions_raw(users, rev_start, rev_end)
    # TODO: query by username instead of (local home wiki) user_id, or query by
    # global id. This will be necessary to pull revision data for a user on
    # any wiki except their home wiki where we have their local user_id.
    user_list = compile_usernames_query(users)
    oauth_tags = compile_oauth_tags
    oauth_tags = oauth_tags.blank? ? oauth_tags : "&#{oauth_tags}"
    query = user_list + oauth_tags + "&start=#{rev_start}&end=#{rev_end}"
    api_get('revisions.php', query)
  end

  # Given a list of users, fetch their global_id and trained status. Completion
  # of training is defined by the users.php endpoint as having made an edit
  # to a specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def get_user_info(users)
    # TODO: switch to usernames to make queries wiki-agnostic.
    query = compile_usernames_query(users)
    if ENV['training_page_id']
      query = "#{query}&training_page_id=#{ENV['training_page_id']}"
    end
    api_get('users.php', query)
  end

  # Given a list of articles *or* hashes of the form { 'mw_page_id' => 1234 },
  # see which ones have not been deleted.
  def get_existing_articles_by_id(articles)
    article_list = compile_article_ids_query(articles)
    existing_articles = api_get('articles.php', article_list)
    existing_articles
  end

  # Given a list of articles *or* hashes of the form { 'title' => 'Something' },
  # see which ones have not been deleted.
  def get_existing_articles_by_title(articles)
    article_list = compile_article_titles_query(articles)
    existing_articles = api_get('articles.php', article_list)
    existing_articles
  end

  # Given a list of revisions, see which ones have not been deleted
  def get_existing_revisions_by_id(revisions)
    revision_list = compile_revision_ids_query(revisions)
    existing_revisions = api_get('revisions.php', revision_list)
    existing_revisions
  end

  ###################
  # Private methods #
  ###################

  private

  # Given an endpoint (either 'users.php' or 'revisions.php') and a
  # query appropriate to that endpoint, return the parsed json response.
  #
  # Example users.php query with 2 users:
  #   http://tools.wmflabs.org/wikiedudashboard/users.php?user_ids[0]=012345&user_ids[1]=678910
  # Example users.php parsed response with 2 users:
  # [{"id"=>"123", "wiki_id"=>"User_A", "global_id"=>"8675309", trained: 1},
  #  {"id"=>"6789", "wiki_id"=>"User_B", "global_id"=>"9035768", trained: 0}]
  #
  # Example revisions.php query:
  #   http://tools.wmflabs.org/wikiedudashboard/revisions.php?user_ids[0]=%27Example_User%27&user_ids[1]=%27Ragesoss%27&user_ids[2]=%27Sage%20(Wiki%20Ed)%27&start=20150105&end=20150108
  #
  # Example revisions.php parsed response:
  # [{"page_id"=>"44962463",
  #   "page_title"=>"Swarfe/ENGL-122-2014",
  #   "page_namespace"=>"2",
  #   "rev_id"=>"641297913",
  #   "rev_timestamp"=>"20150106205746",
  #   "rev_user_text"=>"Sage (Wiki Ed)",
  #   "rev_user"=>"21515199",
  #   "new_article"=>"false",
  #   "byte_change"=>"38"},
  #  {"page_id"=>"44962463",
  #   "page_title"=>"Swarfe/ENGL-122-2014",
  #   "page_namespace"=>"2",
  #   "rev_id"=>"641298113",
  #   "rev_timestamp"=>"20150106205902",
  #   "rev_user_text"=>"Sage (Wiki Ed)",
  #   "rev_user"=>"21515199",
  #   "new_article"=>"false",
  #   "byte_change"=>"-50"
  #  }]
  def api_get(endpoint, query='')
    tries ||= 3
    response = do_query(endpoint, query)
    return if response.empty?
    parsed = JSON.parse response.to_s
    return unless parsed['success']
    parsed['data']
  rescue StandardError => e
    tries -= 1
    sleep 2 && retry unless tries.zero?

    report_exception e, endpoint, query
  end

  def do_query(endpoint, query)
    url = compile_query_url(endpoint, query)
    Net::HTTP::get(URI.parse(url))
  end

  def compile_query_url(endpoint, query)
    base_url = 'http://tools.wmflabs.org/wikiedudashboard/'
    raw_url = "#{base_url}#{endpoint}?lang=#{@wiki.language}&project=#{@wiki.project}&#{query}"
    raw_url
  end

  def compile_usernames_query(users)
    { usernames: users.map(&:username) }.to_query
  end

  def compile_oauth_tags
    oauth_ids = ENV['oauth_ids']
    return '' if oauth_ids.nil?
    oauth_id_tags = oauth_ids.split(',').map { |id| "'OAuth CID: #{id}'" }
    { oauth_tags: oauth_id_tags }.to_query
  end

  # Compile an article list to send to the replica endpoint, which might look
  # something like this:
  # "article_ids[]='Artist'&article_ids[]='Microsoft_Research'"
  def compile_article_titles_query(articles)
    quoted_titles = articles.map { |article| "'#{CGI.escape(article['title'])}'" }
    { article_titles: quoted_titles }.to_query
  end

  # Compile an article list to send to the replica endpoint, which might look
  # something like this:
  # "article_ids[]=100&article_ids[]=300"
  def compile_article_ids_query(articles)
    article_page_ids = articles.map { |article| article['mw_page_id'] }
    { article_ids: article_page_ids }.to_query
  end

  def compile_revision_ids_query(revisions)
    { revision_ids: revisions.map(&:mw_rev_id) }.to_query
  end

  def report_exception(error, endpoint, query, level='error')
    Rails.logger.error "replica.rb #{endpoint} query failed after 3 tries: #{error}"
    level = 'warning' if typical_errors.include?(error.class)
    Raven.capture_exception error,
                            level: level,
                            extras: { query: query,
                                      endpoint: endpoint,
                                      language: @wiki.language,
                                      project: @wiki.project }
    return nil
  end

  # These are typical network errors that we expect to encounter.
  def typical_errors
    [Errno::ETIMEDOUT,
     Net::ReadTimeout,
     Errno::ECONNREFUSED,
     JSON::ParserError]
  end
end
