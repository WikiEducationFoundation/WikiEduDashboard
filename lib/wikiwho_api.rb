# frozen_string_literal: true

# Requests to the WikiWho API, which attributes every token of a Wikipedia
# article's wikitext to the revision that added it. It covers mainspace
# articles on a set of Wikipedia languages; the article viewer's authorship
# highlighting uses the same service.
# API docs: https://wikiwho-api.wmcloud.org/en/api/v1.0.0-beta/
class WikiWhoApi
  BASE_URL = 'https://wikiwho-api.wmcloud.org'
  TIMEOUT = 60 # seconds; long articles take a while to process

  def initialize(wiki)
    @wiki = wiki
  end

  # Returns the tokens of +rev_id+, each a hash with 'str' (lowercased),
  # 'o_rev_id' (the revision that added it) and 'editor' (a user id, or
  # '0|<ip>' for unregistered editors). Returns nil when WikiWho cannot answer,
  # for example for a language it does not cover.
  def rev_content(rev_id)
    response = connection.get(rev_content_path(rev_id), REV_CONTENT_PARAMS)
    return unless response.success?

    body = Oj.load(response.body)
    return unless body['success']

    body['revisions'].first&.values&.first&.dig('tokens')
  rescue Faraday::Error, Oj::ParseError => e
    Sentry.capture_exception(e, level: 'warning', extra: { rev_id:, wiki: @wiki.domain })
    nil
  end

  private

  REV_CONTENT_PARAMS = { o_rev_id: true, editor: true, token_id: false,
                         out: false, in: false }.freeze

  def rev_content_path(rev_id)
    "/#{@wiki.language}/api/v1.0.0-beta/rev_content/rev_id/#{rev_id}/"
  end

  def connection
    Faraday.new(url: BASE_URL, request: { timeout: TIMEOUT }) do |conn|
      conn.headers['User-Agent'] = "#{ENV['dashboard_url']} #{Rails.env}"
    end
  end
end
