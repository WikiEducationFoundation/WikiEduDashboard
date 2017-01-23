# frozen_string_literal: true
class RocketChat
  CHAT_SERVER = 'https://dashboardchat.wmflabs.org'

  def initialize(user: nil, course: nil)
    raise ChatDisabledError unless Features.enable_chat?
    @user = user
    @course = course
    # Rocket.Chat must be configured to permit all valid user/channel names.
    @username = user.username.tr(' ', '_') if @user
    @admin_username = ENV['chat_admin_username']
    @admin_password = ENV['chat_admin_password']
  end

  def login_credentials
    create_chat_account unless @user.chat_password
    get_auth_data(@username, @user.chat_password)
  end

  CREATE_ROOM_ENDPOINT = '/api/v1/channels.create'
  def create_channel_for_course
    data = { name: @course.slug }
    api_post(CREATE_ROOM_ENDPOINT, data, admin_auth_header)
  end

  CREATE_USER_ENDPOINT = '/api/v1/users.create'
  def create_chat_account
    return if @user.chat_password
    @user.chat_password = random_password
    response = api_post(CREATE_USER_ENDPOINT, new_chat_account_data, admin_auth_header)
    unless response.code == '200'
      pp response.body
      raise StandardError
    end
    # TODO: verify success better
    @user.update_attribute(:chat_password, @user.chat_password)
  end

  private

  def api_post(endpoint, data, header = {})
    uri = URI.parse(CHAT_SERVER + endpoint)
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    post = Net::HTTP::Post.new(uri.path, header)
    post.body = data.to_json
    response = http.request(post)
    response
  end

  def admin_login
    return if @admin_token && @admin_id
    admin_auth = get_auth_data(@admin_username, @admin_password)
    @admin_token = admin_auth['authToken']
    @admin_id = admin_auth['userId']
  end

  def admin_auth_header
    admin_login
    {
      'X-Auth-Token' => @admin_token,
      'X-User-Id' => @admin_id,
      'Content-Type' => 'application/json'
    }
  end

  def new_chat_account_data
    {
      username: @username,
      name: @user.username,
      password: @user.chat_password,
      # This field is required by Rocket.Chat, but we don't want to expose this
      # to users or copy their emails to another database. Rocket.Chat requires
      # unique emails, so we set it to their username.
      email: @user.id.to_s + '@wikiedu.org'
    }
  end

  def get_auth_data(username, password)
    login_uri = URI("#{CHAT_SERVER}/api/v1/login")
    post_data = { username: username, password: password }
    response = Net::HTTP.post_form(login_uri, post_data)
    unless response.code == '200'
      pp response.body
      raise StandardError
    end
    JSON.parse(response.body).dig('data')
  end

  RANDOM_PASSWORD_LENGTH = 12
  def random_password
    ('a'..'z').to_a.sample(RANDOM_PASSWORD_LENGTH).join
  end

  class ChatDisabledError < StandardError; end
end
