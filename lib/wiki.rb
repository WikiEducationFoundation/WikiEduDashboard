require 'media_wiki'
require 'crack'

class Wiki

  # Parsing methods
  def self.get_student_count_in_course(course_id)
    response = get_student_list(course_id)
    response["students"]["username"].count
  end

  def self.get_students_in_course(course_id)
    response = get_student_list(course_id)
    response["students"]["username"]
  end

  def self.get_user_revisions_to_article(title, user)
    response = get_revision_data(title, user)
    response["query"]["pages"]["page"]["revisions"]["rev"]
  end

  def self.get_user_first_revision_to_article(title, user)
    response = get_revision_data(title, user)
    response["query"]["pages"]["page"]["revisions"]["rev"][0]
  end


  # Request methods
  def self.get_student_list(course_id)
    Wiki.api_get({
      'action' => 'liststudents',
      'courseids' => course_id,
      'format' => 'json'
    })
  end

  def self.get_revision_data(title, user, start="2007-05-01".to_date, limit=5)
    Wiki.api_get({
      'action' => 'query',
      'prop' => 'revisions',
      'titles' => title,
      'rvlimit' => limit,
      'rvdir' => 'newer',
      'rvstart' => start.to_time.utc.iso8601,
      'rvprop' => 'timestamp|user|comment',
      'rvuser' => user,
      'rawcontinue' => true # This reflects a problem in the media_wiki gem 
    })
  end


  private
  def self.api_get(options={})
    @mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')
    @mw.login(Figaro.env.wikipedia_username!, Figaro.env.wikipedia_password!)
    response = @mw.send_request(options)
    parsed = Crack::XML.parse response.to_s
    parsed["api"]
  end

end