# frozen_string_literal: true

require 'mediawiki_api'
require 'json'
require_dependency "#{Rails.root}/lib/article_rating_extractor.rb"
require_dependency "#{Rails.root}/lib/errors/api_error_handling"

#= This class is for getting data directly from the MediaWiki API.
class WikiApi
  include ApiErrorHandling

  def initialize(wiki = nil, update_service = nil)
    wiki ||= Wiki.default_wiki
    @api_url = wiki.api_url
    @update_service = update_service
  end

  ################
  # Entry points #
  ################

  # General entry point for making arbitrary queries of a MediaWiki wiki's API.
  # An optional block can be passed to intercept errors: if the block returns
  # truthy for a given exception, the exception bubbles up to the caller
  # without retry or Sentry logging. Otherwise the default retry/log/return-nil
  # behavior applies.
  def query(query_parameters, &caller_handles)
    http_method = query_parameters[:http_method] || :get
    mediawiki('query', query_parameters.merge(http_method:), &caller_handles)
  end

  def meta(type, params = {})
    @mediawiki = api_client
    @mediawiki.meta(type, params)
  end

  # Returns nil if it cannot get any info from the wiki, but returns
  # empty string if it's a 404 because the page is a redlink.
  def get_page_content(page_title)
    response = mediawiki('get_wikitext', page_title)
    case response&.status
    when 200
      response.body.force_encoding('UTF-8')
    when 404
      ''
    else
      raise PageFetchError.new(page_title, response&.status)
    end
  end

  def get_user_id(username)
    info = get_user_info(username)
    return unless info
    info['userid']
  end

  def get_user_info(username)
    user_query = { list: 'users',
                   ususers: username,
                   usprop: 'centralids|registration' }
    user_data = mediawiki('query', user_query)
    return unless user_data&.data&.dig('users')&.any?
    user_data.data['users'][0]
  end

  def redirect?(page_title)
    response = get_page_info([page_title])
    return false if response.nil?
    redirect = response['pages']&.values&.dig(0, 'redirect')
    redirect ? true : false
  end

  def get_page_info(titles)
    query_params = { prop: 'info',
                     titles: }
    response = query(query_params)
    response&.status == 200 ? response.data : nil
  end

  def get_article_rating(titles)
    titles = [titles] unless titles.is_a?(Array)
    titles = titles.sort_by(&:downcase)

    query_parameters = { titles:,
                         prop: 'pageassessments',
                         redirects: 'true' }
    response = fetch_all(query_parameters)
    pages = response['pages']
    ArticleRatingExtractor.new(pages).ratings
  end

  ###################
  # Private methods #
  ###################
  private

  def fetch_all(query)
    @query = query
    @data = {}
    until @continue == 'done'
      @query.merge! @continue unless @continue.nil?
      response = mediawiki('query', @query)
      return @data unless response # fall back gracefully if the query fails
      @data.deep_merge! response.data
      # The 'continue' value is nil if the batch is complete
      @continue = response['continue'] || 'done'
    end

    @data
  end

  def mediawiki(action, query, &caller_handles)
    tries ||= 3
    @mediawiki = api_client
    @mediawiki.send(action, query)
  rescue StandardError => e
    raise if caller_handles&.call(e)
    tries -= 1
    if too_many_requests?(e)
      @update_service&.record_too_many_requests
      sleep retry_delay_for(e)
    end
    retry unless tries.zero?
    log_error(e, update_service: @update_service,
              sentry_extra: rate_limit_sentry_extra(e).merge(action:, query:, api_url: @api_url),
              sentry_tags: rate_limit_sentry_tags(e))
    return nil
  end

  def rate_limit_sentry_tags(error)
    return unless too_many_requests?(error)
    { http_status: 429, host: URI(@api_url).host }
  end

  # Per Wikimedia's rate-limit policy: honor Retry-After when present, else
  # back off ≥5 s. https://www.mediawiki.org/wiki/Wikimedia_APIs/Rate_limits
  DEFAULT_RETRY_AFTER_SECONDS = 5
  # Cap to prevent a misbehaving server from hanging a worker for hours.
  MAX_RETRY_AFTER_SECONDS = 60

  def retry_delay_for(error)
    seconds = retry_after_seconds(error) || DEFAULT_RETRY_AFTER_SECONDS
    seconds.clamp(0, MAX_RETRY_AFTER_SECONDS)
  end

  # Returns the integer seconds requested by the server's Retry-After header,
  # or nil if the header is absent / unparseable / the gem version in use
  # doesn't expose the response on HttpError. Wikimedia uses delay-seconds;
  # HTTP-date form (RFC 7231) is not parsed.
  def retry_after_seconds(error)
    return nil unless error.respond_to?(:response) && error.response
    raw = error.response.headers['Retry-After']
    Integer(raw) if raw.present?
  rescue ArgumentError, TypeError
    nil
  end

  def rate_limit_sentry_extra(error)
    raw = retry_after_seconds(error)
    raw ? { retry_after: raw } : {}
  end

  def api_client
    MediawikiApi::Client.new @api_url
  end

  def too_many_requests?(e)
    return false unless e.instance_of?(MediawikiApi::HttpError)
    e.status == 429
  end

  class PageFetchError < StandardError
    attr_reader :status

    def initialize(page, status)
      @status = status
      message = "Failed to fetch content for #{page} with response status: #{status.inspect}"
      super(message)
    end
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Faraday::ConnectionFailed,
                    MediawikiApi::HttpError,
                    MediawikiApi::ApiError].freeze
end
