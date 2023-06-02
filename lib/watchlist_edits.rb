# frozen_string_literal: true

class WatchlistEdits
  def initialize(wiki = nil, my_array = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
    @my_array = my_array || []
  end

  def oauth_credentials_valid?(current_user)
    return { status: 'no current user' } unless current_user
    fetch_watch_token(current_user)
    add_to_watchlist
  end

  # Adds the user's page(s) to the watchlist using the obtained watch token.
  def add_to_watchlist
    return { status: 'no watch token' } if @watch_token.nil?
    data = build_watchlist_data
    @access_token.post(@wiki.api_url.to_s, data)
  end

  private

  # Fetches the watch token from the MediaWiki API for the specified user
  def fetch_watch_token(current_user, type = 'watch')
    return { status: 'no current user' } unless current_user

    # Request a watchtoken token for the user
    @access_token = oauth_access_token(current_user)
    get_token = @access_token.get(
      "#{@wiki.api_url}?action=query&meta=tokens&format=json&type=#{type}"
    )

    # Handle 5XX response for when MediaWiki API is down
    handle_mediawiki_server_errors(get_token) { return { status: 'failed' } }

    # Handle Mediawiki API response
    token_response = Oj.load(get_token.body)
    handle_token_response_errors(token_response) { |err| return { status: 'failed', error: err } }
    # Watchtoken
    @watch_token = (token_response['query']['tokens']['watchtoken']).to_s
  end

  def oauth_consumer
    OAuth::Consumer.new ENV['wikipedia_token'], ENV['wikipedia_secret'],
                        client_options: { site: "https://#{@wiki.language}.#{@wiki.project}.org" }
  end

  def oauth_access_token(user)
    OAuth::AccessToken.new(oauth_consumer, user.wiki_token, user.wiki_secret)
  end

  def handle_mediawiki_server_errors(response)
    return unless /^5../.match?(response.code.to_s)
    Sentry.capture_message('Wikimedia API is down')
    yield
  end

  def handle_token_response_errors(token_response)
    return if token_response.key?('query')
    error = token_response['error'] if token_response.key?('error')
    yield error
  end

  # Build the data hash for adding pages to the watchlist
  def build_watchlist_data
    {
      action: 'watch',
      format: 'json',
      titles: @my_array.join('|'),
      token: @watch_token,
      formatversion: '2'
    }
  end
end
