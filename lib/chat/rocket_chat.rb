# frozen_string_literal: true
class RocketChat
  CHAT_SERVER = 'https://dashboardchat.wmflabs.org'

  def initialize(user: nil, course: nil)
    @user = user
    @course = course
    @admin_username = ENV['chat_admin_username']
    @admin_password = ENV['chat_admin_password']
  end

  def login_token
    # TODO
  end

  CREATE_ROOM_ENDPOINT = '/api/v1/channels.create'
  def create_room_for_course
    data = { name: @course.id.to_s }
    api_post(CREATE_ROOM_ENDPOINT, data, admin_auth_header)
  end

  CREATE_USER_ENDPOINT = '/api/v1/users.create'
  def create_chat_account
    data = {
      username: @user.username,
      name: @user.username,
      password: 'testing',
      email: 'dashboard@wikiedu.org'
    }
    api_post(CREATE_USER_ENDPOINT, data, admin_auth_header)
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

  def get_auth_data(username, password)
    login_uri = URI("#{CHAT_SERVER}/api/v1/login")
    post_data = { username: username, password: password }
    response = Net::HTTP.post_form(login_uri, post_data)
    JSON.parse(response.body).dig('data')
  end
end
