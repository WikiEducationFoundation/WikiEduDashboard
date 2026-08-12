# frozen_string_literal: true

class LtiSession
  attr_reader :idtoken

  INSTRUCTOR_ROLES = [
    'membership#Administrator',
    'membership#Instructor',
    'membership#Mentor'
  ].freeze

  SCORE_MAXIMUM = 1

  private_constant :SCORE_MAXIMUM

  def initialize(ltiaas_domain, api_key, ltik)
    @ltiaas_domain = ltiaas_domain
    @api_key = api_key
    @ltik = ltik

    @conn = Faraday.new(url: "https://#{@ltiaas_domain}") do |config|
      config.headers['Authorization'] = "LTIK-AUTH-V2 #{@api_key}:#{@ltik}"
      config.request :json
      config.response :json
    end

    @idtoken = make_get_request('/api/idtoken')
    @cached_line_item_id = nil
  end

  def user_lti_id
    @idtoken['user']['id']
  end

  def user_name
    @idtoken['user']['name']
  end

  def user_email
    @idtoken['user']['email']
  end

  def user_is_teacher?
    @idtoken['user']['roles'].any? do |str|
      INSTRUCTOR_ROLES.any? { |suffix| str.end_with?(suffix) }
    end
  end

  def lms_id
    @idtoken['platform']['id']
  end

  def lms_family
    @idtoken['platform']['productFamilyCode']
  end

  def context_id
    "#{@idtoken['launch']['context']['id']}::#{@idtoken['launch']['resourceLink']['id']}"
  end

  def line_item_id
    @cached_line_item_id ||= determine_line_item_id
  end

  def resolve_user_from_lti_identity
    return nil if @user_lti_id.blank?
    LtiContext.find_by(user_lti_id: @user_lti_id)&.user
  end

  def link_lti_user(current_user)
    # Checking if LTI User already exists.
    return unless LtiContext.find_by(user: current_user, user_lti_id:, lms_id:, context_id:).nil?
    # Creating LTI User
    @lti_record = LtiContext.create!(user: current_user, user_lti_id:, lms_id:, lms_family:,
context_id:)
      # Sending account created signal if user is a student.
      # You can pass the User Wikipedia ID as parameter to this method to
      #  generate a comment in the grade.
      # Example: lti_session.send_account_created_signal(123)
    send_account_created_signal(current_user.username) unless user_is_teacher?
  end

  private

  def send_account_created_signal(user_wikipedia_id = nil)
    score = {
      'scoreGiven' => SCORE_MAXIMUM,
      'scoreMaximum' => SCORE_MAXIMUM,
      'activityProgress' => 'Completed',
      'gradingProgress' => 'FullyGraded',
      'userId' => @idtoken['user']['id']
    }
    score['comment'] = "Wikipedia user ID: #{user_wikipedia_id}" unless user_wikipedia_id.nil?
    make_post_request("/api/lineitems/#{CGI.escape(line_item_id)}/scores", score)
  end

  def make_get_request(path)
    response = @conn.get(path)
    raise LtiaasClientError.new(response.body, response.status) unless response.success?
    return response.body
  end

  def make_post_request(path, body)
    response = @conn.post(path, body)
    raise LtiaasClientError.new(response.body, response.status) unless response.success?
    return response.body
  end

  def determine_line_item_id
    unless @idtoken['services']['assignmentAndGrades']['available']
      raise LtiGradingServiceUnavailable
    end

    line_item_id = @idtoken['services']['assignmentAndGrades']['lineItemId']
    return line_item_id unless line_item_id.nil? || line_item_id.empty?

    resource_link_id = @idtoken['launch']['resourceLink']['id']
    line_items = make_get_request("/api/lineitems?resourceLinkId=#{resource_link_id}")['lineItems']
    return line_items.first['id'] unless line_items.empty?

    line_item = {
      'label' => 'WikiEdu Account Creation',
      'resourceLinkId' => resource_link_id,
      'scoreMaximum' => SCORE_MAXIMUM
    }
    return make_post_request('/api/lineitems', line_item)['id']
  end

  def build_and_submit_deep_link(resource)
    content_item = build_content_item(resource)
    create_deep_linking_form([content_item])
  end

  def build_content_item(resource)
    {
      type: "ltiResourceLink",
      url: "#{ltiaas_launch_url}?resource_type=#{resource.class.name}&resource_id=#{resource.id}",
      title: resource.title
    }
  end

  def create_deep_linking_form(content_items)
    unless @idtoken['services']['deepLinking']['available']
      raise LtiDeepLinkingServiceUnavailable
    end
    unless user_is_teacher?
      render status: :forbidden
      raise LtiaasClientError
    end

    body = {
      contentItems: content_items
    }
    response = make_post_request("/api/deeplinking/form", body)
    response['form']
  end

  class LtiaasClientError < StandardError
    attr_reader :response_body, :status_code

    def initialize(response_body, status_code)
      @response_body = response_body
      @status_code = status_code
      super("LTIAAS Request failed: #{response_body}")
    end
  end

  class LtiGradingServiceUnavailable < StandardError; end
  class LtiDeepLinkingServiceUnavailable < StandardError; end
end
