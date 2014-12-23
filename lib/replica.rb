require 'crack'

class Replica


  def self.connect_to_tool
    self.api_get('')
  end


  # Parsing methods
  def self.get_bytes_for_revision(revision_id)
  end


  # Request methods
  def self.get_articles_edited_this_term_by_users(users)
    user_list = self.compile_user_string(users)
    query = user_list + "&start=#{CourseList.start}&end=#{CourseList.end}"
    self.api_get("articles.php", query)
  end

  def self.get_articles_edited_by_user(user_id)
    response = self.api_get("articles.php", "user_ids=#{user_id}")
  end

  def self.get_articles_edited_by_class(class_id)

  end

  def self.get_revisions_this_term_by_users(users)
    user_list = self.compile_user_string(users)
    query = user_list + "&start=#{CourseList.start}&end=#{CourseList.end}"
    self.api_get("revisions.php", query)
  end

  def self.get_revisions_by_user(user_id)
  end

  def self.get_users_completed_training(users)
    user_list = self.compile_user_string(users)
    self.api_get("training.php", user_list)
  end


  private
  def self.api_get(endpoint, query='')
    url = "http://tools.wmflabs.org/wikiedudashboard/#{endpoint}?#{query}"
    response = Net::HTTP::get(URI.parse(url))
    parsed = Crack::JSON.parse response.to_s
    parsed["data"]
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