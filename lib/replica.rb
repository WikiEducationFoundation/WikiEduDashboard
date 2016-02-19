require 'crack'

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   http://tools.wmflabs.org/wikiedudashboard
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  def initialize(wiki)
    @wiki = wiki
  end

  def self.connect_to_tool
    # TODO: Explicitly index.php?
    new(Wiki.default_wiki).ping()
  end

  ###################
  # Parsing methods #
  ###################

  # Given a list of users and a start and end date, return a nicely formatted
  # array of revisions made by those users between those dates.
  def get_revisions(users, rev_start, rev_end)
    raw = get_revisions_raw(users, rev_start, rev_end)
    data = {}
    return data unless raw.is_a?(Enumerable)
    raw.each do |revision|
      parsed = parse_revision(revision)
      page_id = parsed['article']['page_id']
      unless data.include?(page_id)
        data[page_id] = {}
        data[page_id]['article'] = parsed['article']
        data[page_id]['revisions'] = []
      end
      data[page_id]['revisions'].push parsed['revision']
    end
    data
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
    article_data = {}
    article_data['page_id'] = revision['page_id']
    article_data['title'] = revision['page_title']
    article_data['namespace'] = revision['page_namespace']
    article_data['wiki_id'] = @wiki.id

    revision_data = {}
    revision_data['rev_id'] = revision['rev_id']
    revision_data['date'] = revision['rev_timestamp'].to_datetime
    revision_data['characters'] = revision['byte_change']
    revision_data['page_id'] = revision['page_id']
    revision_data['user_id'] = revision['rev_user']
    revision_data['new_article'] = revision['new_article']
    revision_data['system'] = revision['system']

    { 'article' => article_data, 'revision' => revision_data }
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
    # TODO: waiting for the backend change
    # user_list = compile_usernames_string(users)
    user_list = compile_user_ids_string(users)
    oauth_tags = compile_oauth_tags
    oauth_tags = oauth_tags.blank? ? oauth_tags : "&#{oauth_tags}"
    query = user_list + oauth_tags + "&start=#{rev_start}&end=#{rev_end}"
    api_get('revisions_by_user_id.php', query)
  end

  # Given a list of users, fetch their global_id and trained status. Completion
  # of training is defined by the users.php endpoint as having made an edit
  # to a specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def get_user_info(users)
    # TODO: usernames, see above
    query = compile_user_ids_string(users)
    if ENV['training_page_id']
      query = "#{query}&training_page_id=#{ENV['training_page_id']}"
    end
    api_get('users.php', query)
  end

  # Given a list of articles, see which ones have not been deleted.
  # FIXME: inconsistent signature
  def get_existing_articles_by_id(page_ids)
    article_list = compile_article_id_string(page_ids)
    existing_articles = api_get('articles.php', article_list)
    # FIXME: What does this do?
    existing_articles unless existing_articles.nil?
  end

  # Given a list of articles, see which ones have not been deleted.
  def get_existing_articles_by_title(articles)
    article_list = compile_article_title_string(articles)
    existing_articles = api_get('articles.php', article_list)
    existing_articles unless existing_articles.nil?
  end

  # Given a list of revisions, see which ones have not been deleted
  def get_existing_revisions_by_id(revisions)
    revision_list = compile_revision_id_string(revisions)
    existing_revisions = api_get('revisions.php', revision_list)
    existing_revisions unless existing_revisions.nil?
  end

  def ping()
    api_get('')
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
  #   http://tools.wmflabs.org/wikiedudashboard/revisions.php?usernames_User%27&usernames_ids[2]=%27Sage%20(Wiki%20Ed)%27&start=20150105&end=20150108
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
    url = compile_query_url(endpoint, query)
    response = Net::HTTP::get(URI.parse(url))
    return unless response.length > 0
    parsed = JSON.parse response.to_s
    parsed['data']
  rescue StandardError => e
    tries -= 1
    unless tries.zero?
      sleep 2
      retry
    end
    report_exception e, endpoint, query
  end

  def compile_query_url(endpoint, query)
    base_url = 'http://tools.wmflabs.org/wikiedudashboard/'
    raw_url = "#{base_url}#{endpoint}?lang=#{@wiki.language}&project=#{@wiki.project}&#{query}"
    URI.encode(raw_url)
  end

  # Compile a user list to send to the replica endpoint, which might look
  # something like this:
  # "usernames[]='Ragesoss'&usernames[]='Sage+%28Wiki+Ed%29'"
  def compile_usernames_string(users)
    { usernames: users.map(&:wiki_id) }.to_query
  end

  # Compile a user list to send to the replica endpoint, which might look
  # something like this:
  # "user_ids[0]='Ragesoss'&user_ids[1]='Sage (Wiki Ed)'"
  # FIXME: deprecated
  def compile_user_ids_string(users)
    user_list = ''
    users.each_with_index do |user, i|
      fail unless user.id
      user_list += '&' if i > 0
      user_list += "user_ids[#{i}]='#{user.id}'"
    end
    user_list
  end

  def compile_oauth_tags
    tag_list = ''
    oauth_ids = ENV['oauth_ids']
    return '' if oauth_ids.nil?
    oauth_ids.split(',').each_with_index do |id, i|
      tag_list += '&' if i > 0
      tag_list += "oauth_tags[#{i}]='OAuth CID: #{id}'"
    end
    tag_list
  end

  # Compile an article list to send to the replica endpoint, which might look
  # something like this:
  # "article_ids[0]='Artist'&article_ids[1]='Microsoft_Research'"
  def compile_article_title_string(articles)
    article_list = ''
    articles.each_with_index do |a, i|
      article_list += '&' if i > 0
      title = CGI.escape(a['title'].tr(' ', '_'))
      article_list += "article_titles[#{i}]='#{title}'"
    end
    article_list
  end

  # Compile an article list to send to the replica endpoint, which might look
  # something like this:
  # "article_ids[0]='100'&article_ids[1]='300'"
  def compile_article_id_string(page_ids)
    # TODO: These are 'page_ids'
    compile_id_string(page_ids, 'article_ids')
  end

  def compile_revision_id_string(revisions)
    # FIXME: wat.  just pass the ids
    rev_ids = revisions.map { |r| { id: r.native_id } }
    compile_id_string(rev_ids, 'revision_ids')
  end

  def compile_id_string(ids, prefix)
    id_list = ''
    ids.each_with_index do |id, index|
      id_list += '&' if index > 0
      id_list += "#{prefix}[#{index}]='#{id['id']}'"
    end
    id_list
  end

  def report_exception(error, endpoint, query, level='error')
    Rails.logger
      .error "replica.rb #{endpoint} query failed after 3 tries: #{error}"
    # These are typical network errors that we expect to encounter.
    typical_errors = [Errno::ETIMEDOUT,
                      Net::ReadTimeout,
                      Errno::ECONNREFUSED,
                      JSON::ParserError]
    level = 'warning' if typical_errors.include?(error.class)
    Raven.capture_exception error,
                            level: level,
                            extras: { query: query, endpoint: endpoint }
    return nil
  end
end
