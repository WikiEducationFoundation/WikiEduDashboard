require 'media_wiki'
require 'crack'

class Wiki


  ###################
  # Parsing methods #
  ###################
  def self.get_course_list
    response = {}
    Figaro.env.cohorts.split(",").each do |cohort|
      response[cohort] = get_page_content(ENV["cohort_" + cohort]).split(/\n/)
    end
    response

    # response["spring_2015"] = get_page_content(ENV["cohort_spring_2015"]).split(/\n/)
    # response
  end


  def self.get_course_info(course_id)
    raw = Wiki.get_course_info_raw(course_id)
    if !raw
      return []
    end

    if raw.is_a?(Array)
      raw.map { |course| Wiki.parse_course_info(course) }
    else
      [Wiki.parse_course_info(raw)]
    end
  end


  def self.parse_course_info(course)
    parsed = { "course" => {}, "participants" => {} }
    course_info = course["name"].split(/(.*)\/(.*)\s\(([^\)]+)/)
    parsed.tap do |p|
      p["course"]["id"] = course["id"]
      p["course"]["slug"] = course["name"].gsub(" ", "_")
      p["course"]["school"] = course_info[1]
      p["course"]["title"] = course_info[2]
      p["course"]["term"] = course_info[3]
      p["course"]["start"] = course["start"].to_date
      p["course"]["end"] = course["end"].to_date

      ["student", "instructor", "online_volunteer", "campus_volunteer"].each do |r|
        p["participants"][r] = course[r + 's'].blank? ? [] : course[r + 's'][r]
      end
    end
  end



  ###################
  # Request methods #
  ###################
  def self.get_page_content(page_title, options={})
    @mw = Wiki.gateway
    options['format'] = 'xml'
    options[:maxlag] = 10
    options['rawcontinue'] = true
    begin
      response = @mw.get(page_title, options)
    rescue MediaWiki::APIError => e
      puts "Caught #{e}"
    end
    response
  end


  def self.get_course_info_raw(course_id)
    if course_id.is_a?(Array)
      course_id = course_id.join('|')
    end
    info = Wiki.api_get({
      'action' => 'liststudents',
      'courseids' => course_id,
      'group' => ''
    })
    info.nil? ? nil : info["course"]
  end



  ###################
  # Private methods #
  ###################
  private
  def self.gateway
    @mw = MediaWiki::Gateway.new('http://en.wikipedia.org/w/api.php')
    begin
      @mw.login(Figaro.env.wikipedia_username!, Figaro.env.wikipedia_password!)
    rescue RestClient::RequestTimeout => e
      puts "Caught #{e}"
      Rails.logger.warn "Caught #{e}"
      Wiki.gateway
    rescue MediaWiki::APIError => e
      puts "Caught #{e}"
      Rails.logger.warn "Caught #{e}"
      Wiki.gateway
    end
    @mw
  end


  def self.api_get(options={})
    @mw = Wiki.gateway
    options['format'] = 'xml'
    options[:maxlag] = 10
    begin
      response = @mw.send_request(options)
    rescue MediaWiki::APIError => e
      Rails.logger.warn "Caught #{e}"
      if(e.to_s.include?("Invalid course id"))
        if(options["courseids"].split('|').count > 1)
          Wiki.api_get Wiki.handle_invalid_course_id(options, e)
        else
          {"course" => false}
        end
      end
    else
      parsed = Crack::XML.parse response.to_s
      parsed["api"]
    end
  end


  def self.handle_invalid_course_id(options, e)
    id = e.to_s[/(?<=MediaWiki::APIError: API error: code 'invalid-course', info 'Invalid course id: ).*?(?=')/]
    if(options["courseids"].include?('|'+id+'|'))
      options["courseids"] = options["courseids"].gsub('|'+id+'|', '|')
    elsif(options["courseids"].include?(id+'|'))
      options["courseids"].slice! id+'|'
    else
      options["courseids"].slice! '|'+id
    end
    options
  end


end