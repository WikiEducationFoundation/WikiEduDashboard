require 'media_wiki'
require 'crack'

class Wiki

  # Parsing methods
  def self.get_student_count_in_course(course_id)
    response = get_student_list(course_id)
    unless response["students"].blank?
      response["students"]["username"].count
    else
      []
    end
  end

  def self.get_students_in_course(course_id)
    response = get_student_list(course_id)
    unless response["students"].blank?
      response["students"]["username"]
    else
      []
    end
  end

  def self.get_user_revisions_to_article(title, user)
    response = get_revision_data(title, user)
    if defined? response["query"]
      response["query"]["pages"]["page"]["revisions"]["rev"]
    end
  end

  def self.get_user_first_revision_to_article(title, user)
    response = get_revision_data(title, user)
    if defined? response["query"]
      response["query"]["pages"]["page"]["revisions"]["rev"][0]
    end
  end


  # Request methods
  def self.get_course_info(course_id)
    if course_id.is_a?(Array)
      course_id = course_id.join('|')
    end
    Wiki.api_get({
      'action' => 'liststudents',
      'courseids' => course_id,
      'group' => ''
    })["course"]
  end

  def self.get_student_list(course_id)
    Wiki.api_get({
      'action' => 'liststudents',
      'courseids' => course_id
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
    options['format'] = 'xml'
    options[:maxlag] = 10
    begin
      response = @mw.send_request(options)
    rescue MediaWiki::APIError => e
      puts "Caught MediaWiki::APIError: #{e}"
      api_get options
    end
    parsed = Crack::XML.parse response.to_s
    parsed["api"]
  end

end