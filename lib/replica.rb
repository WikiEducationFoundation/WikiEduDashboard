require 'crack'

#= Fetches wiki revision data from an endpoint that provides SQL query
#= results from a replica wiki database on wmflabs: http://tools.wmflabs.org/wikiedudashboard
#= For what's going on at the other end, see https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica
  def self.connect_to_tool
    api_get('')
  end

  ###################
  # Parsing methods #
  ###################

  # Given a list of users and a start and end date, return a nicely formatted
  # array of revisions made by those users between those dates.
  def self.get_revisions(users, rev_start, rev_end)
    raw = Replica.get_revisions_raw(users, rev_start, rev_end)
    data = {}
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
    parsed = { 'revision' => {}, 'article' => {} }
    parsed.tap do |p|
      p['article']['id'] = revision['page_id']
      p['article']['title'] = revision['page_title'].gsub('_', ' ')
      p['article']['namespace'] = revision['page_namespace']

      p['revision']['id'] = revision['rev_id']
      p['revision']['date'] = revision['rev_timestamp'].to_datetime
      p['revision']['characters'] = revision['byte_change']
      p['revision']['article_id'] = revision['page_id']
      p['revision']['user_id'] = revision['rev_user']
      p['revision']['new_article'] = revision['new_article']
    end
  end

  ###################
  # Request methods #
  ###################

  # Given a list of users and a start and end date, get data about revisions
  # those users made between those dates.
  # As of 2015-02-24, revisions.php only queries namespaces:
  #   0 ([mainspace])
  #   2 (User:)
  def self.get_revisions_raw(users, rev_start, rev_end)
    user_list = compile_user_string(users)
    query = user_list + "&start=#{rev_start}&end=#{rev_end}"
    api_get('revisions.php', query)
  end

  # Given a list of users, see which ones completed the training. Completion of
  # training is defined by the training.php endpoint as having made an edit to a
  # specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def self.get_users_completed_training(users)
    user_list = compile_user_string(users)
    api_get('training.php', user_list)
  end

  # Given a list of users, fetch their global_id and trained status. Completion
  # of training is defined by the training.php endpoint as having made an edit
  # to a specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def self.get_user_info(users)
    user_list = compile_user_id_string(users)
    api_get('users.php', user_list)
  end

  # Given a list of articles, see which ones have not been deleted.
  def self.get_existing_articles(articles)
    article_list = compile_article_string(articles)
    existing_titles = api_get('articles.php', article_list)
    existing_titles.map { |a| a['page_title'] }
  end

  ###################
  # Private methods #
  ###################

  class << self
    private

    # Given an endpoint (either 'training.php' or 'revisions.php') and a
    # query appropriate to that endpoint, return the parsed json response.
    #
    # Example training.php query with 3 users:
    #    http://tools.wmflabs.org/wikiedudashboard/training.php?user_ids[0]=%27Example_User%27&user_ids[1]=%27Ragesoss%27&user_ids[2]=%27Sage%20(Wiki%20Ed)%27
    # Example training.php parsed response with 2 users who completed training:
    #    [{"rev_user_text"=>"Ragesoss"}, {"rev_user_text"=>"Sage (Wiki Ed)"}]
    #
    # Example revisions.php query:
    #    http://tools.wmflabs.org/wikiedudashboard/revisions.php?user_ids[0]=%27Example_User%27&user_ids[1]=%27Ragesoss%27&user_ids[2]=%27Sage%20(Wiki%20Ed)%27&start=20150105&end=20150108
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
      language = Figaro.env.wiki_language
      base_url = 'http://tools.wmflabs.org/wikiedudashboard/'
      url = "#{base_url}#{endpoint}?lang=#{language}&#{query}"
      response = Net::HTTP::get(URI.parse(url))

      return unless response.length > 0
      parsed = JSON.parse response.to_s
      parsed['data']
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

    # Compile an article list to send to the replica endpoint, which might look
    # something like this:
    # "article_ids[0]='Artist'&article_ids[1]='Microsoft_Research'"
    def compile_article_string(articles)
      article_list = ''
      articles.each_with_index do |a, i|
        article_list += '&' if i > 0
        title = CGI.escape(a['title'].gsub(' ', '_'))
        article_list += "article_titles[#{i}]='#{title}'"
      end
      article_list
    end
  end
end
