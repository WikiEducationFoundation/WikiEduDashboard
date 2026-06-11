# frozen_string_literal: true

require 'oauth2'
require_dependency "#{Rails.root}/lib/importers/user_importer"

class Auth::Oauth2Controller < ApplicationController
  # before_action :require_no_authentication, only: [:mediawiki, :mediawiki_signup]
  skip_before_action :check_for_expired_oauth_credentials, only: [:callback]

  def mediawiki_signup
    start_oauth_flow
  end

  def callback
    if params[:code].present? && params[:state].eql?(session[:oauth_state])
      begin
        client = OAuth2::Client.new(ENV['OAUTH_CONSUMER_TOKEN'],
                                    ENV['OAUTH_CONSUMER_SECRET'],
                                    site: "https://meta.wikimedia.org/w/rest.php",
                                    authorize_url: 'oauth2/authorize',
                                    token_url: 'oauth2/access_token',
                                    connection_opts: {
                                      headers: {
                                        'User-Agent' => ENV['user_agent']
                                      }
                                    },
                                    logger: Logger.new('oauth2.log', 'weekly'),
                                    connection_opts: {
                                      headers: { 'User-Agent' => ENV['user_agent'] }
                                    }
                                    )

        @access_token = client.auth_code.get_token(params[:code],
                                                   redirect_uri: ENV['OAUTH_CALLBACK_URL'],
                                                   client_id: ENV['OAUTH_CONSUMER_TOKEN'],
                                                   client_secret: ENV['OAUTH_CONSUMER_SECRET'])

        reset_session
        set_session

        find_or_create_user

        sign_in_and_redirect @user
      rescue
        @got_token = false
      end
    else
      Rails.logger.error "No authorization code received"
    end
  end

  def find_or_create_user
    user_info = get_user_details(@access_token)
    auth_hash = build_auth_hash(@access_token, user_info, '')

    @user = UserImporter.from_omniauth(auth_hash)
  end

  def set_session
    session[:access_token] = @access_token.token
  end

  # Method to refresh the access token
  def refresh_access_token
    return nil unless session[:refresh_token].present?

    begin
      client = OAuth2::Client.new(ENV['OAUTH_CONSUMER_TOKEN'],
                                  ENV['OAUTH_CONSUMER_SECRET'],
                                  site: "https://meta.wikimedia.org/w/rest.php",
                                  authorize_url: 'oauth2/authorize',
                                  token_url: 'oauth2/access_token')

      # Create a token object from the stored refresh token
      old_token = OAuth2::AccessToken.new(client, session[:access_token], {
                                          refresh_token: session[:refresh_token],
                                          expires_at: session[:token_expires_at]})

      # Refresh the token
      new_token = old_token.refresh!

      # Update session with new tokens
      session[:access_token] = new_token.token
      session[:refresh_token] = new_token.refresh_token if new_token.refresh_token
      session[:token_expires_at] = new_token.expires_at

      Rails.logger.info "Token refreshed successfully"
      Rails.logger.info "New token expires at: #{Time.at(new_token.expires_at)}" if new_token.expires_at

      new_token

      rescue OAuth2::Error => e
        Rails.logger.error "Failed to refresh token: #{e.message}"
        # Clear invalid tokens
        reset_session
       nil
    end
  end

  # Helper method to check if token is expired or about to expire
  def token_expired?
    return true unless session[:token_expires_at].present?

    # Check if token expires in the next 5 minutes
    Time.now.to_i >= (session[:token_expires_at] - 300)
  end

  # Method to get a valid access token (refreshing if needed)
  def current_access_token
    if token_expired?
      Rails.logger.info "Token expired or about to expire, refreshing..."
      new_token = refresh_access_token
      return nil unless new_token
      new_token.token
    else
      session[:access_token]
    end
  end

  def get_user_details(access_token)
    # Option 1: Using MediaWiki Action API
    response = access_token.get('https://meta.wikimedia.org/w/api.php',
                                params: {
                                action: 'query',
                                meta: 'userinfo',
                                uiprop: 'email|realname|groups',
                                format: 'json' })

    data = JSON.parse(response.body)
    user_data = data.dig('query', 'userinfo')

    {
      id: user_data['id'],
      username: user_data['name'],
      email: user_data['email'],
      realname: user_data['realname'],
      groups: user_data['groups']
    }

    rescue => e
      Rails.logger.error "Failed to fetch user details: #{e.message}"
    nil
  end

  private

  def start_oauth_flow
    client = OAuth2::Client.new(ENV['OAUTH_CONSUMER_TOKEN'],
                                ENV['OAUTH_CONSUMER_SECRET'],
                                site: "https://meta.wikimedia.org/w/rest.php",
                                authorize_url: 'oauth2/authorize',
                                token_url: 'oauth2/access_token' ,
                                logger: Logger.new('oauth2.log', 'weekly'))

    session['oauth_state'] = SecureRandom.hex(16)

    @oauth_url = client.auth_code.authorize_url(redirect_uri: ENV['OAUTH_CALLBACK_URL'], state: session['oauth_state'])

    redirect_to @oauth_url
  end


  def build_auth_hash(access_token, user_info, identity)
    return nil unless user_info

    {
      'provider' => 'mediawiki_oauth2',
      'uid' => user_info[:id],
      'info' => {
        'name' => user_info[:username],
        'email' => user_info[:email]
      },
      'credentials' => {
        'token' => access_token.token,
        'refresh_token' => access_token.refresh_token,
        'expires_at' => access_token.expires_at,
        'expires' => access_token.expires?
      }
    }
  end
end
