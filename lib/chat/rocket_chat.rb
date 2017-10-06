# frozen_string_literal: true

class RocketChat
  def initialize(user: nil, course: nil)
    raise ChatDisabledError unless Features.enable_chat?
    @user = user
    @course = course
    # Rocket.Chat must be configured to permit all valid user/channel names.
    @username = @user.username.tr(' ', '_') if @user
    @chat_server = ENV['chat_server']
    @admin_username = ENV['chat_admin_username']
    @admin_password = ENV['chat_admin_password']
  end

  def login_credentials
    create_chat_account unless @user.chat_password
    get_auth_data(@username, @user.chat_password)
  end

  # Creates a private group channel, vs. 'channels.create' for a public channel
  CREATE_ROOM_ENDPOINT = '/api/v1/groups.create'
  def create_channel_for_course
    return unless Features.enable_course_chat?(@course)
    return if @course.chatroom_id
    data = { name: @course.slug }
    response = api_post(CREATE_ROOM_ENDPOINT, data, admin_auth_header)
    room_id = JSON.parse(response.body).dig('group', '_id')
    raise StandardError unless room_id
    @course.update_attribute(:chatroom_id, room_id)
  end

  ADD_TO_CHANNEL_ENDPOINT = '/api/v1/groups.invite'
  def add_user_to_course_channel
    return unless Features.enable_course_chat?(@course)
    create_chat_account unless @user.chat_id
    create_channel_for_course unless @course.chatroom_id
    add_user_data = {
      roomId: @course.chatroom_id,
      userId: @user.chat_id
    }
    api_post(ADD_TO_CHANNEL_ENDPOINT, add_user_data, admin_auth_header)
  end

  private

  CREATE_USER_ENDPOINT = '/api/v1/users.create'
  def create_chat_account
    return if @user.chat_id
    @user.chat_password = random_password
    response = api_post(CREATE_USER_ENDPOINT, new_chat_account_data, admin_auth_header)
    # TODO: verify success better
    chat_id = JSON.parse(response.body).dig('user', '_id')
    raise StandardError unless chat_id
    @user.update(chat_password: @user.chat_password, chat_id: chat_id)
  end

  def api_post(endpoint, data, header = {})
    uri = URI.parse(@chat_server + endpoint)
    http = Net::HTTP.new(uri.host, 443)
    http.use_ssl = true
    post = Net::HTTP::Post.new(uri.path, header)
    post.body = data.to_json
    response = http.request(post)
    validate_api_response(response, endpoint)
    response
  end

  def validate_api_response(response, endpoint)
    return if response.code == '200'
    Raven.capture_message 'Rocket.Chat API error',
                          level: 'error',
                          extra: { response_data: response.body,
                                   endpoint: endpoint,
                                   user: @username }
    raise RocketChatAPIError
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
      'Content-type' => 'application/json'
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

  LOGIN_ENDPOINT = '/api/v1/login'
  def get_auth_data(username, password)
    login_uri = URI(@chat_server + LOGIN_ENDPOINT)
    post_data = { username: username, password: password }
    response = Net::HTTP.post_form(login_uri, post_data)
    validate_api_response(response, LOGIN_ENDPOINT)
    JSON.parse(response.body).dig('data')
  end

  RANDOM_PASSWORD_LENGTH = 12
  def random_password
    ('a'..'z').to_a.sample(RANDOM_PASSWORD_LENGTH).join
  end

  class ChatDisabledError < StandardError; end
  class RocketChatAPIError < StandardError; end
end
