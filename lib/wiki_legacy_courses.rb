require 'mediawiki_api'
require 'json'

#= This class is for getting data from the Wikipedia liststudents API.
class WikiLegacyCourses
  ################
  # Entry points #
  ################
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

  ##################
  # Helper methods #
  ##################
  def self.course_query(course_ids)
    courseids_param = course_ids.join('|')
    query_parameters = { token_type: false,
                         courseids: courseids_param,
                         group: '' }
    query_parameters
  end

  ###################
  # Private methods #
  ###################
  class << self
    private

    # Query the liststudents API to get info about a course. For example:
    # http://en.wikipedia.org/w/api.php?action=liststudents&courseids=30&group=
    def get_course_info_raw(course_ids)
      course_ids = Array.wrap(course_ids)
      query_parameters = course_query course_ids
      response = api_client.action 'liststudents', query_parameters
      info = response.data
      info.nil? ? nil : info
    rescue MediawikiApi::ApiError => e
      # The message for invalid course ids looks like this:
      # "Invalid course id: 953"
      if e.info[0..16] == 'Invalid course id'
        handle_invalid_course_id course_ids, e.info
      else
        handle_api_error e
      end
    end

    def api_client
      language = ENV['wiki_language']
      url = "https://#{language}.wikipedia.org/w/api.php"
      MediawikiApi::Client.new url
    end

    def handle_invalid_course_id(course_ids, error_info)
      invalid = error_info[19..-1].to_i # This is the invalid id.
      course_ids.delete(invalid)
      if course_ids.blank?
        return false # This indicates that the course doesn't exist
      else
        get_course_info_raw course_ids
      end
    end

    def handle_api_error(e)
      Rails.logger.warn 'Caught #{e}'
      Raven.capture_exception e, level: 'warning'
      nil # because Raven captures return 'true' if successful
    end
  end
end
