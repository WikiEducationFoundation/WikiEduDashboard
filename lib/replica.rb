require 'crack'

# This class fetches wiki revision data from an endpoint that provides SQL query
# results from a replica wiki database on wmflabs: http://tools.wmflabs.org/wikiedudashboard
# For what's going on at the other end, see https://github.com/WikiEducationFoundation/WikiEduDashboardTools
class Replica


  def self.connect_to_tool
    self.api_get('')
  end


  ###################
  # Parsing methods #
  ###################

  # Given a list of users and a start and end date, return a nicely formatted
  # array of revisions made by those users between those dates.
  def self.get_revisions_this_term_by_users(users, rev_start, rev_end)
    raw = Replica.get_revisions_this_term_by_users_raw(users, rev_start, rev_end)
    data = {}
    if raw.is_a?(Array)
      raw.each do |revision|
        parsed = Replica.parse_revision(revision)
        if !data.include?(parsed["article"]["id"])
          data[parsed["article"]["id"]] = {}
          data[parsed["article"]["id"]]["article"] = parsed["article"]
          data[parsed["article"]["id"]]["revisions"] = []
        end
        data[parsed["article"]["id"]]["revisions"].push parsed["revision"]
      end
    elsif !raw.nil?
      Replica.parse_revision(raw)
    end
    data
  end

  # Given a single raw json revision, parse it into a more useful format.
  #
  # Example raw revision input:
  #   {"page_id"=>"418355", "page_title"=>"Babbling", "page_namespace"=>"0", "rev_id"=>"641327984", "rev_timestamp"=>"20150107003430", "rev_user_text"=>"Ragesoss", "rev_user"=>"319203", "new_article"=>"false", "byte_change"=>"121"}
  #
  # Example parsed revision output:
  #  {"revision"=>{"id"=>"641327984", "date"=>Wed, 07 Jan 2015 00:34:30 +0000, "characters"=>"121", "article_id"=>"418355", "user_id"=>"319203", "new_article"=>"false"}, "article"=>{"id"=>"418355", "title"=>"Babbling", "namespace"=>"0"}}
  def self.parse_revision(revision)
    parsed = { "revisions" => [] }
    parsed = { "revision" => {}, "article" => {} }
    parsed.tap do |p|
      p["article"]["id"] = revision["page_id"]
      p["article"]["title"] = revision["page_title"].gsub("_", " ")
      p["article"]["namespace"] = revision["page_namespace"]

      p["revision"]["id"] = revision["rev_id"]
      p["revision"]["date"] = revision["rev_timestamp"].to_datetime
      p["revision"]["characters"] = revision["byte_change"]
      p["revision"]["article_id"] = revision["page_id"]
      p["revision"]["user_id"] = revision["rev_user"]
      p["revision"]["new_article"] = revision["new_article"]
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
  def self.get_revisions_this_term_by_users_raw(users, rev_start, rev_end)
    user_list = self.compile_user_string(users)
    query = user_list + "&start=#{rev_start}&end=#{rev_end}"
    Replica.api_get("revisions.php", query)
  end

  # Given a list of users, see which ones completed the training. Completion of
  # training is defined by the training.php endpoint as having made an edit to a
  # specific page on Wikipedia:
  # [[Wikipedia:Training/For students/Training feedback]]
  def self.get_users_completed_training(users)
    user_list = self.compile_user_string(users)
    self.api_get("training.php", user_list)
  end


  ###################
  # Private methods #
  ###################
  private

  # Given an endpoint — either 'training.php' or 'revisions.php' — and an query
  # appropriate to that endpoint, return the parsed json response.
  #
  # Example training.php query with 3 users:
  #    http://tools.wmflabs.org/wikiedudashboard/training.php?user_ids[0]=%27Example_User%27&user_ids[1]=%27Ragesoss%27&user_ids[2]=%27Sage%20(Wiki%20Ed)%27
  # Example training.php parsed response with 2 users who completed training:
  #    [{"rev_user_text"=>"Ragesoss"}, {"rev_user_text"=>"Sage (Wiki Ed)"}]
  #
  # Example revisions.php query:
  #    http://tools.wmflabs.org/wikiedudashboard/revisions.php?user_ids[0]=%27Example_User%27&user_ids[1]=%27Ragesoss%27&user_ids[2]=%27Sage%20(Wiki%20Ed)%27&start=20150105&end=20150108
  # Example revisions.php parsed response:
  #    [{"page_id"=>"418355", "page_title"=>"Babbling", "page_namespace"=>"0", "rev_id"=>"641327984", "rev_timestamp"=>"20150107003430", "rev_user_text"=>"Ragesoss", "rev_user"=>"319203", "new_article"=>"false", "byte_change"=>"121"}, {"page_id"=>"44962463", "page_title"=>"Swarfe/ENGL-122-2014", "page_namespace"=>"2", "rev_id"=>"641297356", "rev_timestamp"=>"20150106205401", "rev_user_text"=>"Sage (Wiki Ed)", "rev_user"=>"21515199", "new_article"=>"false", "byte_change"=>"7"}, {"page_id"=>"44962463", "page_title"=>"Swarfe/ENGL-122-2014", "page_namespace"=>"2", "rev_id"=>"641297494", "rev_timestamp"=>"20150106205453", "rev_user_text"=>"Sage (Wiki Ed)", "rev_user"=>"21515199", "new_article"=>"false", "byte_change"=>"14"}, {"page_id"=>"44962463", "page_title"=>"Swarfe/ENGL-122-2014", "page_namespace"=>"2", "rev_id"=>"641297913", "rev_timestamp"=>"20150106205746", "rev_user_text"=>"Sage (Wiki Ed)", "rev_user"=>"21515199", "new_article"=>"false", "byte_change"=>"38"}, {"page_id"=>"44962463", "page_title"=>"Swarfe/ENGL-122-2014", "page_namespace"=>"2", "rev_id"=>"641298113", "rev_timestamp"=>"20150106205902", "rev_user_text"=>"Sage (Wiki Ed)", "rev_user"=>"21515199", "new_article"=>"false", "byte_change"=>"-50"}]
  def self.api_get(endpoint, query='')
    url = "http://tools.wmflabs.org/wikiedudashboard/#{endpoint}?#{query}"
    response = Net::HTTP::get(URI.parse(url))
    # unless response.length > 100000
    if response.length > 0
      parsed = JSON.parse response.to_s
      parsed["data"]
    else
      nil
    end
  end

  # Compile a user list to send to the replica endpoint, which might look
  # something like this:
  # "user_ids[0]='Ragesoss'&user_ids[1]='Sage (Wiki Ed)'&user_ids[2]='Example User'"
  def self.compile_user_string(users)
    user_list = ""
    users.each_with_index do |u, i|
      if i > 0
        user_list += "&"
      end
      wiki_id = CGI.escape(u.wiki_id)
      user_list += "user_ids[#{i}]='#{wiki_id}'"
    end
    user_list
  end


end
