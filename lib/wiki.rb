require 'mediawiki_api'
require 'json'

#= This class is for getting data directly from the Wikipedia API.
class Wiki
  ################
  # Entry points #
  ################

  # General entry point for making arbitrary queries of the Wikipedia API
  def self.query(query_parameters)
    wikipedia.query query_parameters
  end

  def self.get_page_content(page_title)
    response = wikipedia.get_wikitext page_title
    response.status == 200 ? response.body : nil
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

  # Based on the cohorts and wiki pages defined in application.yml, get the list
  # of courses for each cohort.
  def self.course_list
    response = {}
    Cohort.all.each do |cohort|
      content = get_page_content(cohort.url)
      next if content.nil?
      lines = content.split(/\n/)
      # Only integers can be valid ids.
      integers = /^[1-9][0-9]*$/
      raw_ids = lines.select { |id| integers.match(id) }
      raw_ids = raw_ids.map(&:to_i)
      response[cohort.slug] = raw_ids
    end
    response
  end

  def self.get_article_rating(titles)
    titles = [titles] unless titles.is_a?(Array)
    titles = titles.sort_by(&:downcase)

    talk_titles = titles.map { |title| 'Talk:' + title }
    raw = get_raw_page_content(talk_titles)
    return [] unless raw

    # Pages that are missing get returned before pages that exist, so we cannot
    # count on our array being in the same order as titles.
    raw.map do |_article_id, talkpage|
      # Remove "Talk:" from the "title" value to get the title.
      { talkpage['title'][5..-1].gsub(' ', '_') =>
        parse_article_rating(talkpage) }
    end
  end

  ###################
  # Parsing methods #
  ###################

  def self.parse_course_info(course)
    append = course['name'][-1, 1] != ')' ? ' ()' : ''
    course_slug_info = (course['name'] + append)
                       .split(%r{(.*)/(.*)\s\(([^\)]+)?\)})
    course_info = {}
    course_info['id'] = course['id']
    course_info['slug'] = course['name'].gsub(' ', '_')
    course_info['school'] = course_slug_info[1]
    course_info['title'] = course_slug_info[2]
    course_info['term'] = course_slug_info[3]
    course_info['start'] = course['start'].to_date
    course_info['end'] = course['end'].to_date

    participants = {}
    roles = %w(student instructor online_volunteer campus_volunteer)
    roles.each do |r|
      participants[r] = course[r + 's']
    end

    { 'course' => course_info, 'participants' => participants }
  end

  def self.parse_article_rating(raw_talk)
    # Handle MediaWiki API errors
    return nil if raw_talk.nil?
    # Handle the case of nonexistent talk pages.
    return nil if raw_talk['missing']

    wikitext = raw_talk['revisions'][0]['*']
    ApplicationController.helpers.find_article_class wikitext
  end

  ##############################
  # Additional request methods #
  ##############################

  # Query the liststudents API to get info about a course. For example:
  # http://en.wikipedia.org/w/api.php?action=liststudents&courseids=30&group=
  def self.get_course_info_raw(course_ids)
    course_ids = [course_ids] unless course_ids.is_a?(Array)
    courseids_param = course_ids.join('|')
    response = wikipedia.action 'liststudents',
                                token_type: false,
                                courseids: courseids_param,
                                group: ''
    info = response.data
    info.nil? ? nil : info
  rescue MediawikiApi::ApiError => e
    # The message for invalid course ids looks like this:
    # "Invalid course id: 953"
    if e.info[0..16] == 'Invalid course id'
      invalid = e.info[19..-1].to_i # This is the invalid id.
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

    def handle_api_error(e)
      Rails.logger.warn 'Caught #{e}'
      Raven.capture_exception e, level: 'warning'
      nil # because Raven captures return 'true' if successful
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
