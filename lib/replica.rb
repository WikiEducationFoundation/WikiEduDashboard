require 'crack'

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs:
#=   http://tools.wmflabs.org/wikiedudashboard
#= For what's going on at the other end, see:
#=   https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  def self.connect_to_tool
    api_get('')
  end

  ###################
  # Parsing methods #
  ###################

  # Given a list of users and a start and end date, return a nicely formatted
  # array of revisions made by those users between those dates.
  def self.get_revisions(users, rev_start, rev_end, language=nil)
    raw = Replica.get_revisions_raw(users, rev_start, rev_end, language)
    data = {}
    return data unless raw.is_a?(Enumerable)
    raw.each do |revision|
      parsed = Replica.parse_revision(revision)
      article_id = parsed['article']['id']
      unless data.include?(article_id)
        data[article_id] = {}
        data[article_id]['article'] = parsed['article']
        data[article_id]['revisions'] = []
      end
      data[article_id]['revisions'].push parsed['revision']
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
  def self.parse_revision(revision)
    article_data = {}
    article_data['id'] = revision['page_id']
    article_data['title'] = revision['page_title']
    article_data['namespace'] = revision['page_namespace']

    revision_data = {}
    revision_data['id'] = revision['rev_id']
    revision_data['date'] = revision['rev_timestamp'].to_datetime
    revision_data['characters'] = revision['byte_change']
    revision_data['article_id'] = revision['page_id']
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
  def self.get_revisions_raw(users, rev_start, rev_end, language=nil)
    user_list = compile_user_string(users)
    oauth_tags = compile_oauth_tags
    oauth_tags = oauth_tags.blank? ? oauth_tags : "&#{oauth_tags}"
    query = user_list + oauth_tags + "&start=#{rev_start}&end=#{rev_end}"
    api_get('revisions.php', query, language)
  end

  # Given a list of users, fetch their global_id and trained status. Completion
  # of training is defined by the users.php endpoint as having made an edit
  # to a specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def self.get_user_info(users, language=nil)
    query = compile_user_id_string(users)
    if Figaro.env.training_page_id?
      query = "#{query}&training_page_id=#{Figaro.env.training_page_id}"
    end
    api_get('users.php', query, language)
  end

  def self.get_user_id(username, language=nil)
    api_get('user_id.php', "user_name='#{username}'", language)['user_id']
  end

  # Given a list of articles, see which ones have not been deleted.
  def self.get_existing_articles_by_id(articles, language=nil)
    article_list = compile_article_id_string(articles)
    existing_articles = api_get('articles.php', article_list, language)
    existing_articles unless existing_articles.nil?
  end

  # Given a list of articles, see which ones have not been deleted.
  def self.get_existing_articles_by_title(articles, language=nil)
    article_list = compile_article_title_string(articles)
    existing_articles = api_get('articles.php', article_list, language)
    existing_articles unless existing_articles.nil?
  end

  # Given a list of revisions, see which ones have not been deleted
  def self.get_existing_revisions_by_id(revisions, language=nil)
    revision_list = compile_revision_id_string(revisions)
    existing_revisions = api_get('revisions.php', revision_list, language)
    existing_revisions unless existing_revisions.nil?
  end

  ###################
  # Private methods #
  ###################

  class << self
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
    def api_get(endpoint, query='', language=nil)
      tries ||= 3
      url = compile_query_url(endpoint, query, language)
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

    def compile_query_url(endpoint, query, language=nil)
      language ||= ENV['wiki_language']
      base_url = 'http://tools.wmflabs.org/wikiedudashboard/'
      raw_url = "#{base_url}#{endpoint}?lang=#{language}&#{query}"
      URI.encode(raw_url)
    end

    # Compile a user list to send to the replica endpoint, which might look
    # something like this:
    # "user_ids[0]='Ragesoss'&user_ids[1]='Sage (Wiki Ed)'"
    def compile_user_string(users)
      user_list = ''
      users.each_with_index do |u, i|
        user_list += '&' if i > 0
        wiki_id = CGI.escape(u.wiki_id)
        user_list += "user_ids[#{i}]='#{wiki_id}'"
      end
      user_list
    end

    def compile_user_id_string(users)
      user_list = ''
      users.each_with_index do |u, i|
        user_list += '&' if i > 0
        user_list += "user_ids[#{i}]='#{u.id}'"
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
        title = CGI.escape(a['title'].gsub(' ', '_'))
        article_list += "article_titles[#{i}]='#{title}'"
      end
      article_list
    end

    # Compile an article list to send to the replica endpoint, which might look
    # something like this:
    # "article_ids[0]='100'&article_ids[1]='300'"
    def compile_article_id_string(articles)
      article_list = ''
      articles.each_with_index do |a, i|
        article_list += '&' if i > 0
        article_id = a['id']
        article_list += "article_ids[#{i}]='#{article_id}'"
      end
      article_list
    end

    def compile_revision_id_string(revisions)
      revision_list = ''
      revisions.each_with_index do |r, i|
        revision_list += '&' if i > 0
        revision_list += "revision_ids[#{i}]='#{r['id']}'"
      end
      revision_list
    end

    def report_exception(error, endpoint, query, level='error')
      Rails.logger
        .error "replica.rb #{endpoint} query failed after 3 tries: #{error}"
      # These are typical network errors that we expect to encounter.
      typical_errors = [Errno::ETIMEDOUT,
                        Errno::ECONNREFUSED,
                        JSON::ParserError]
      level = 'warning' if typical_errors.include?(error.class)
      Raven.capture_exception error,
                              level: level,
                              extras: { query: query, endpoint: endpoint }
      return nil
    end
  end
end
