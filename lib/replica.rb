require 'crack'

class Replica


  def self.connect_to_tool
    self.api_get('')
  end


  ###################
  # Parsing methods #
  ###################
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
    else
      Replica.parse_revision(raw)
    end
    data
  end


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
  def self.get_revisions_this_term_by_users_raw(users, rev_start, rev_end)
    user_list = self.compile_user_string(users)
    query = user_list + "&start=#{rev_start}&end=#{rev_end}"
    Replica.api_get("revisions.php", query)
  end


  def self.get_users_completed_training(users)
    user_list = self.compile_user_string(users)
    self.api_get("training.php", user_list)
  end


  ###################
  # Private methods #
  ###################
  private
  def self.api_get(endpoint, query='')
    url = "http://tools.wmflabs.org/wikiedudashboard/#{endpoint}?#{query}"
    response = Net::HTTP::get(URI.parse(url))
    # unless response.length > 100000
    parsed = Crack::JSON.parse response.to_s
    parsed["data"]
    # end
  end


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