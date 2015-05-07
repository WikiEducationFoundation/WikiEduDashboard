require 'mediawiki_api'
require 'crack'
require 'json'

#= This class is for getting data directly from the Wikipedia API.
class Wiki
  ###################
  # Parsing methods #
  ###################

  # Based on the cohorts and wiki pages defined in application.yml, get the list
  # of courses for each cohort.
  def self.course_list
    response = {}
    Cohort.all.each do |cohort|
      content = get_page_content(cohort.url)
      response[cohort.slug] = content.split(/\n/) unless content.nil?
    end
    response
  end

  def self.get_course_info(course_ids)
    raw = get_course_info_raw(course_ids)
    return [nil] if raw.nil? # This indicates a failure to get the course data.
    return [] unless raw # This indicates that the course(s) don't exist.

    info = []
    (0...raw.count).each do |course|
      raw_course_info = raw[course.to_s]
      course_info = parse_course_info(raw_course_info)
      info.append(course_info)
    end
    info
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
        p['participants'][r] = course[r + 's']
      end
    end
  end

  def self.get_article_rating(titles)
    titles = [titles] unless titles.is_a?(Array)
    titles = titles.sort_by(&:downcase)

    talk_titles = titles.map { |at| 'Talk:' + at }
    raw = get_raw_page_content(talk_titles)
    return [] unless raw

    # Pages that are missing get returned before pages that exist, so we cannot
    # count on our array being in the same order as titles.
    raw.map do |article_id, article|
      # Remove "Talk:" from the "title" value to get the title.
      { article['title'][5..-1] => parse_article_rating(article) }
    end
  end

  def self.parse_article_rating(raw_article)
    # Handle MediaWiki API errors
    return nil if raw_article.nil?
    # Handle the case of nonexistent talk pages.
    return nil if raw_article['missing']

    article = raw_article['revisions'][0]['*']
    find_article_class article
  end

  # Try to find the Wikipedia 1.0 rating of an article by parsing its talk page
  # contents.
  #
  # Adapted from https://en.wikipedia.org/wiki/User:Pyrospirit/metadata.js
  # alt https://en.wikipedia.org/wiki/MediaWiki:Gadget-metadata.js
  # We simplify this parser by folding the nonstandard ratings
  # into the corresponding standard ones. We don't want to deal with edge cases
  # like bplus and a/ga.
  def self.find_article_class(article)
    # Handle empty talk page
    return nil if article.is_a? Hash
        # rubocop:disable Metrics/LineLength
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
    # rubocop:enable Metrics/LineLength
  end

  ###################
  # Request methods #
  ###################
  def self.get_page_content(page_title)
    response = wikipedia.get_wikitext page_title
    response.status == 200 ? response.body : nil
  end

  # Query the liststudents API to get info about a course. For example:
  # http://en.wikipedia.org/w/api.php?action=liststudents&courseids=30&group=
  def self.get_course_info_raw(course_ids)
    course_ids = [course_ids] unless course_ids.is_a?(Array)
    courseids_param = course_ids.join('|')
    response = wikipedia.action 'liststudents',
                                {
                                  token_type: false,
                                  courseids: courseids_param,
                                  group: ''
                                }
    info = response.data
    info.nil? ? nil : info
  rescue MediawikiApi::ApiError => e
    # The message for invalid course ids looks like this:
    # "Invalid course id: 953"
    if e.info[0..16] == 'Invalid course id'
      invalid = e.info[19..-1] # This is the invalid id.
      handle_invalid_course_id course_ids, invalid
    else
      handle_api_error e
    end
  end

  # Get raw page content for one or more pages titles, which can be parsed to
  # find the article ratings. (The corresponding Talk page are the one with the
  # relevant info.) Example query:
  # http://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rawcontinue=true&redirects=true&titles=Talk:Selfie
  def self.get_raw_page_content(article_titles)
    info = wikipedia.query titles: article_titles,
                           prop: 'revisions',
                           rvprop: 'content'
    page = info.data['pages']
    page.nil? ? nil : page
  rescue NoMethodError => e
    Rails.logger.warn "Could not get rating(s) for #{article_title}"
    Raven.capture_exception e
    return nil
  rescue MediawikiApi::ApiError => e
    handle_api_error e
  end

  ###################
  # Private methods #
  ###################
  class << self
    private

    def wikipedia
      language = Figaro.env.wiki_language
      url = "https://#{language}.wikipedia.org/w/api.php"
      @wikipedia = MediawikiApi::Client.new url
      @wikipedia
    end

    def handle_api_error(e, options=nil)
      Rails.logger.warn 'Caught #{e}'
      Raven.capture_exception e, level: 'warning'
      return nil # because Raven captures return 'true' if successful
    end

    def handle_invalid_course_id(course_ids, invalid)
      course_ids.delete(invalid)
      if course_ids.blank?
        return false # This indicates that the course doesn't exist
      else
        get_course_info_raw course_ids
      end
    end
  end
end
