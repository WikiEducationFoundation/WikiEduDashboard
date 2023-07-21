# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/wiki_edits"
class WatchlistEdits < WikiEdits
  def initialize(wiki = nil, current_user= nil)
    super(wiki)
    @current_user = current_user
  end

  # Adds the user's page(s) to the watchlist using the obtained tokens.
  def watch_userpages(users)
    return { status: 'no users' } if users.empty?
    return { status: 'token retrieval failed' } unless retrieve_tokens

    data = watch_action_parameters(users)
    response = @access_token.post(@wiki.api_url.to_s, data)
    response_data = Oj.load(response.body)
    response_data
  end

  private

  # Build the data hash for adding pages to the watchlist
  def watch_action_parameters(users)
    {
      action: 'watch',
      format: 'json',
      titles: users.join('|'),
      token: @watch_token,
      formatversion: '2'
    }
  end

  # Retrieves OAuth tokens for watchlist edits if the credentials are valid
  def retrieve_tokens
    return false unless oauth_credentials_valid?(@current_user)

    tokens = OpenStruct.new(get_tokens(@current_user, 'watch'))
    @watch_token = tokens.action_token
    @access_token = tokens.access_token

    !(@watch_token.nil? || @access_token.nil?)
  end
end
