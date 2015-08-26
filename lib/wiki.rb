require 'mediawiki_api'
require 'json'

#= This class is for getting data directly from the Wikipedia API.
class Wiki
  ################
  # Entry points #
  ################

  # General entry point for making arbitrary queries of the Wikipedia API
  def self.query(query_parameters, opts={})
    wikipedia('query', query_parameters, opts)
  end

  def self.get_page_content(page_title, language=nil)
    response = wikipedia('get_wikitext', page_title, language: language)
    response.status == 200 ? response.body : nil
  end

  def self.get_user_id(username, language=nil)
    user_query = { list: 'users',
                   ususers: username }
    user_data = wikipedia('query', user_query, language: language)
    user_id = user_data.data['users'][0]['userid']
    user_id
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

  def self.parse_article_rating(raw_talk)
    # Handle MediaWiki API errors
    return nil if raw_talk.nil?
    # Handle the case of nonexistent talk pages.
    return nil if raw_talk['missing']

    wikitext = raw_talk['revisions'][0]['*']
    ApplicationController.helpers.find_article_class wikitext
  end

  #####################
  # Other API methods #
  #####################

  # Get raw page content for one or more pages titles, which can be parsed to
  # find the article ratings. (The corresponding Talk page are the one with the
  # relevant info.) Example query:
  # http://en.wikipedia.org/w/api.php?action=query&prop=revisions&rvprop=content&rawcontinue=true&redirects=true&titles=Talk:Selfie
  def self.get_raw_page_content(article_titles, language=nil)
    query_parameters = { titles: article_titles,
                         prop: 'revisions',
                         rvprop: 'content' }
    info = wikipedia('query', query_parameters, language: language)
    return if info.nil?
    page = info.data['pages']
    page.nil? ? nil : page
  end

  ###################
  # Private methods #
  ###################
  class << self
    private

    def wikipedia(action, query, opts = {})
      tries ||= 3
      @mediawiki = api_client(opts)
      @mediawiki.send(action, query)
    rescue MediawikiApi::ApiError => e
      handle_api_error e
    rescue StandardError => e
      tries -= 1
      typical_errors = [Faraday::TimeoutError,
                        Faraday::ConnectionFailed,
                        MediawikiApi::HttpError]
      if typical_errors.include?(e.class)
        retry if tries >= 0
        Raven.capture_exception e, level: 'warning'
      else
        raise e
      end
    end

    def api_client(opts)
      site = opts[:site]
      language = opts[:language] || ENV['wiki_language']

      if site
        url = "https://#{site}/w/api.php"
      else
        url = "https://#{language}.wikipedia.org/w/api.php"
      end
      MediawikiApi::Client.new url
    end

    def handle_api_error(e)
      Rails.logger.warn 'Caught #{e}'
      Raven.capture_exception e, level: 'warning'
      fail e if e.code == 'iiurlparamnormal' # handled by Commons.rb
    end
  end
end
