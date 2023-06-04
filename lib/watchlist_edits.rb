# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"
class WatchlistEdits < WikiEdits
  def initialize(wiki = nil, my_array = nil)
    super(wiki)
    @my_array = my_array || []
  end

  def oauth_credentials_valid?(current_user)
    super(current_user)
    tokens = OpenStruct.new(get_tokens(current_user, 'watch'))
    @watch_token = tokens.action_token
    @access_token = tokens.access_token
    add_to_watchlist
  end

  # Adds the user's page(s) to the watchlist using the obtained watch token.
  def add_to_watchlist
    return { status: 'no watch token' } if @watch_token.nil?
    data = build_watchlist_data
    @access_token.post(@wiki.api_url.to_s, data)
  end

  private

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
