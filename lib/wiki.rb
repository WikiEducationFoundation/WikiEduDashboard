require 'media_wiki'
require 'crack'

#= This class is for getting data directly from the Wikipedia API.
class Wiki
  ###################
  # Parsing methods #
  ###################

  # Based on the cohorts and wiki pages defined in application.yml, get the list
  # of courses for each cohort.
  def self.course_list
    response = {}
    Figaro.env.cohorts.split(',').each do |cohort|
      response[cohort] = get_page_content(ENV['cohort_' + cohort]).split(/\n/)
    end
    response
  end

  def self.get_course_info(course_id)
    raw = get_course_info_raw(course_id)
    return [] unless raw

    if raw.is_a?(Array)
      raw.map { |course| parse_course_info(course) }
    else
      [parse_course_info(raw)]
    end
  end

  def self.parse_course_info(course)
    parsed = { 'course' => {}, 'participants' => {} }
    append = course['name'][-1, 1] != ')' ? ' ()' : ''
    course_info = (course['name'] + append).split(/(.*)\/(.*)\s\(([^\)]+)?\)/)
    parsed.tap do |p|
      p['course']['id'] = course['id']
      p['course']['slug'] = course['name'].gsub(' ', '_')
      p['course']['school'] = course_info[1]
      p['course']['title'] = course_info[2]
      p['course']['term'] = course_info[3]
      p['course']['start'] = course['start'].to_date
      p['course']['end'] = course['end'].to_date

      roles = %w(student instructor online_volunteer campus_volunteer)
      roles.each do |r|
        p['participants'][r] = course[r + 's'].blank? ? [] : course[r + 's'][r]
      end
    end
  end

  def self.get_article_rating(article_title)
    if article_title.is_a?(Array)
      article_title = article_title.sort_by(&:downcase)
    end
    titles = article_title

    if titles.is_a?(Array)
      titles = article_title.map { |at| 'Talk:' + at }
    else
      titles = 'Talk:' + article_title
    end

    raw = get_article_rating_raw(titles)
    return [] unless raw

    # Pages that are missing get returned before pages that exist, so we cannot
    # count on our array being in the same order as article_title.
    if raw.is_a?(Array)
      raw.each_with_index.map do |article|
        # Remove "Talk:" from the "title" value to get the title.
        { article['title'][5..-1] => parse_article_rating(article) }
      end
    else
      [{ article_title => parse_article_rating(raw) }]
    end
  end

  # Try to find the Wikipedia 1.0 rating of an article by parsing its talk page
  # contents.
  #
  # Adapted from https://en.wikipedia.org/wiki/User:Pyrospirit/metadata.js
  # alt https://en.wikipedia.org/wiki/MediaWiki:Gadget-metadata.js
  # We simplify this parser by removing folding the nonstandard ratings
  # into the corresponding standard ones. We don't want to deal with edge cases
  # like bplus and a/ga.
  # rubocop:disable Metrics/LineLength
  def self.parse_article_rating(raw_article)
    # Handle the case of nonexistent talk pages.
    if raw_article['missing']
      article = ''
    else
      article = raw_article['revisions']['rev']
    end

    if article.match(/\|\s*(class|currentstatus)\s*=\s*fa\b/i)
      'fa'
    elsif article.match(/\|\s*(class|currentstatus)\s*=\s*fl\b/i)
      'fl'
    elsif article.match(/\|\s*class\s*=\s*a\b/i)
      'a' # Treat all forms of A, including A/GA, as simple A.
    elsif article.match(/\|\s*class\s*=\s*ga\b|\|\s*currentstatus\s*=\s*(ffa\/)?ga\b|\{\{\s*ga\s*\|/i) && !article.match(/\|\s*currentstatus\s*=\s*dga\b/i)
      'ga'
    elsif article.match(/\|\s*class\s*=\s*b\b/i)
      'b'
    elsif article.match(/\|\s*class\s*=\s*bplus\b/i)
      'b' # Treat B-plus as regular B.
    elsif article.match(/\|\s*class\s*=\s*c\b/i)
      'c'
    elsif article.match(/\|\s*class\s*=\s*start/i)
      'start'
    elsif article.match(/\|\s*class\s*=\s*stub/i)
      'stub'
    elsif article.match(/\|\s*class\s*=\s*list/i)
      'list'
    elsif article.match(/\|\s*class\s*=\s*sl/i)
      'list' # Treat sl as regular list.
    end
    # For other niche ratings like "cur" and "future", count them as unrated.
  end
  # rubocop:enable Metrics/LineLength

  ###################
  # Request methods #
  ###################
  def self.get_page_content(page_title, options={})
    @mw = gateway
    options['format'] = 'xml'
    options[:maxlag] = 10
    options['rawcontinue'] = true
    begin
      response = @mw.get(page_title, options)
    rescue MediaWiki::APIError => e
      Rails.logger.warn "Caught #{e}"
    end
    response
  end

  # Query the liststudents API to get info about a course. For example:
  # http://en.wikipedia.org/w/api.php?action=liststudents&courseids=30&group=
  def self.get_course_info_raw(course_id)
    course_id = course_id.join('|') if course_id.is_a?(Array)
    info = api_get(
      'action' => 'liststudents',
      'courseids' => course_id,
      'group' => ''
    )
    info.nil? ? nil : info['course']
  end

  # Get raw page content for one or more pages titles, which can be parsed to
  # find the article ratings. (The corresponding Talk page are the one with the
  # relevant info.) Example query:
  # http://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rawcontinue=true&redirects=true&titles=Talk:Selfie
  def self.get_article_rating_raw(article_title)
    article_title = article_title.join('|') if article_title.is_a?(Array)
    info = api_get(
      'action' => 'query',
      'prop' => 'revisions',
      'rvprop' => 'content',
      'rawcontinue' => 'true',
      'redirects' => 'true',
      'titles' => article_title
    )
    info = info['query']['pages']['page']
    info.nil? ? nil : info
  end

  ###################
  # Private methods #
  ###################
  class << self
    private

    def gateway
      language = Figaro.env.wiki_language
      @mw = MediaWiki::Gateway.new("http://#{language}.wikipedia.org/w/api.php")
      begin
        username = Figaro.env.wikipedia_username!
        password = Figaro.env.wikipedia_password!
        @mw.login(username, password)
      rescue RestClient::RequestTimeout => e
        Rails.logger.warn "Caught #{e}"
        gateway
      rescue MediaWiki::APIError => e
        Rails.logger.warn "Caught #{e}"
        gateway
      end
      @mw
    end

    def api_get(options={})
      @mw = gateway
      options['format'] = 'xml'
      options[:maxlag] = 10
      begin
        response = @mw.send_request(options)
      rescue MediaWiki::APIError => e
        if e.to_s.include?('Invalid course id')
          if options['courseids'].split('|').count > 1
            api_get handle_invalid_course_id(options, e)
          else
            { 'course' => false }
          end
        else
          Rails.logger.warn 'Caught #{e}'
        end
      else
        parsed = Crack::XML.parse response.to_s
        parsed['api']
      end
    end

    def handle_invalid_course_id(options, e)
      # rubocop:disable Metrics/LineLength
      id = e.to_s[/(?<=MediaWiki::APIError: API error: code 'invalid-course', info 'Invalid course id: ).*?(?=')/]
      # rubocop:enable Metrics/LineLength
      array = options['courseids'].split('|')
      # See Course.update_all_courses, which checks for 2 courses_ids beyond
      # the highest one found in the cohort lists from application.yml.
      unless array.index(id).nil? or array.index(id) >= array.count - 2
        Rails.logger.warn 'Listed course_id #{id} is invalid'
      end
      if options['courseids'].include?('|' + id + '|')
        options['courseids'] = options['courseids'].gsub('|' + id + '|', '|')
      elsif options['courseids'].include?(id + '|')
        options['courseids'].slice! id + '|'
      else
        options['courseids'].slice! '|' + id
      end
      options
    end
  end
end
