# frozen_string_literal: true

require_dependency Rails.root.join('lib/wiki_response')

#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
  end

  #######################
  # Direct entry points #
  #######################
  def oauth_credentials_valid?(current_user)
    get_tokens(current_user)
    current_user.touch
    current_user.wiki_token != 'invalid'
  end

  def notify_untrained(course, current_user)
    untrained_users = course.students_with_overdue_training
    training_link = "https://#{ENV['dashboard_url']}/training/students"
    signed_text = I18n.t('wiki_edits.notify_overdue.message', link: training_link) + ' --~~~~'

    message = { sectiontitle: I18n.t('wiki_edits.notify_overdue.header'),
                text: signed_text,
                summary: I18n.t('wiki_edits.notify_overdue.summary') }

    notify_users(current_user, untrained_users, message)

    # We want to see how much this specific feature gets used, so we send it
    # to Sentry.
    Sentry.capture_message 'WikiEdits.notify_untrained',
                           level: 'info',
                           extra: { sender: current_user.username,
                                    course_name: course.slug,
                                    untrained_count: untrained_users.count }
  end

  ####################
  # Basic edit types #
  ####################
  # These are also entry points.

  def post_whole_page(current_user, page_title, content, summary = nil)
    params = { action: 'edit',
               title: page_title,
               text: content,
               summary:,
               format: 'json' }

    api_post params, current_user
  end

  def add_new_section(current_user, page_title, message)
    params = { action: 'edit',
               title: page_title,
               section: 'new',
               sectiontitle: message[:sectiontitle],
               text: message[:text],
               summary: message[:summary],
               format: 'json' }

    api_post params, current_user
  end

  def add_to_page_top(page_title, current_user, content, summary)
    params = { action: 'edit',
               title: page_title,
               prependtext: content,
               summary:,
               format: 'json' }

    api_post params, current_user
  end

  ##################
  # Create account #
  ##################

  # Create an account, with a random password to be emailed by mediawiki to the
  # email provided.
  # Success response: {"createaccount"=>{"status"=>"PASS", "username"=>"Ragetest 99"}}
  # Fail response: {"createaccount"=>{"status"=>"FAIL",
  # "message"=>"Nom d’utilisateur entré déjà utilisé.\nVeuillez
  # choisir un nom différent.", "messagecode"=>"userexists"}}
  def create_account(creator:, username:, email:, reason: '')
    params = { action: 'createaccount',
               username:,
               email:,
               mailpassword: 1,
               reason:,
               # This is a required parameter for the API, which is used for
               # multi-step account creation where, for example, the end user must
               # solve a CAPTCHA before the process finishes.
               # We don't use that flow, though, so this could be anything.
               createreturnurl: "https://#{ENV['dashboard_url']}",
               format: 'json' }
    api_post(params, creator, token_name: :createtoken, token_type: 'createaccount')
  end

  ###################
  # Helper methods #
  ###################

  def notify_users(current_user, recipient_users, message)
    recipient_users.each do |recipient|
      add_new_section(current_user, recipient.talk_page, message)
    end
  end

  ###############
  # API methods #
  ###############
  def api_post(data, current_user, token_name: :token, token_type: 'csrf')
    return {} if Features.disable_wiki_output?
    tokens = get_tokens(current_user, token_type)
    return tokens unless tokens['action_token']
    data[token_name] = tokens.action_token

    # Make the request
    response = tokens.access_token.post(@wiki.api_url, data)
    response_data = Oj.load(response.body)
    WikiResponse.capture(response_data, current_user:,
                                        post_data: data,
                                        type: data[:action])
    response_data
  end

  private

  def get_tokens(current_user, type = 'csrf')
    return { status: 'no current user' } unless current_user

    # Request a CSRF or other token for the user
    @access_token = oauth_access_token(current_user)
    get_token = @access_token.get(
      "#{@wiki.api_url}?action=query&meta=tokens&format=json&type=#{type}"
    )

    # Handle 5XX response for when MediaWiki API is down
    handle_mediawiki_server_errors(get_token) { return { status: 'failed' } }

    # Handle Mediawiki API response
    token_response = Oj.load(get_token.body)
    WikiResponse.capture(token_response, current_user:, type: 'tokens')
    handle_token_response_errors(token_response) { |err| return { status: 'failed', error: err } }

    OpenStruct.new(action_token: token_response['query']['tokens']["#{type}token"],
                   access_token: @access_token)
  end

  def oauth_consumer
    OAuth::Consumer.new ENV['wikipedia_token'], ENV['wikipedia_secret'],
                        client_options: { site: "https://#{@wiki.language}.#{@wiki.project}.org" }
  end

  def oauth_access_token(user)
    OAuth::AccessToken.new(oauth_consumer, user.wiki_token, user.wiki_secret)
  end

  def handle_mediawiki_server_errors(response)
    return unless /^5../.match?(response.code)
    Sentry.capture_message('Wikimedia API is down')
    yield
  end

  def handle_token_response_errors(token_response)
    return if token_response.key?('query')
    error = token_response['error'] if token_response.key?('error')
    yield error
  end
end
