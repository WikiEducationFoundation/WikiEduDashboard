require "#{Rails.root}/lib/wiki_response"

#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  def initialize(wiki = nil)
    wiki ||= Wiki.default_wiki
    @wiki = wiki
    @api_url = "https://#{@wiki.language}.#{@wiki.project}.org/w/api.php"
  end

  #######################
  # Direct entry points #
  #######################
  def oauth_credentials_valid?(current_user)
    get_tokens(current_user)
    current_user.wiki_token != 'invalid'
  end

  def notify_untrained(course, current_user)
    untrained_users = course.students.untrained

    message = { sectiontitle: I18n.t('wiki_edits.notify_untrained.header'),
                text: I18n.t('wiki_edits.notify_untrained.message'),
                summary: I18n.t('wiki_edits.notify_untrained.summary') }

    notify_users(current_user, untrained_users, message)

    # We want to see how much this specific feature gets used, so we send it
    # to Sentry.
    Raven.capture_message 'WikiEdits.notify_untrained',
                          level: 'info',
                          culprit: 'WikiEdits.notify_untrained',
                          extra: { sender: current_user.username,
                                   course_name: course.slug,
                                   untrained_count: untrained_users.count }
  end

  def notify_user(sender, recipient, message)
    add_new_section(sender, recipient.talk_page, message)
  end

  ####################
  # Basic edit types #
  ####################
  # These are also entry points.

  def post_whole_page(current_user, page_title, content, summary = nil)
    params = { action: 'edit',
               title: page_title,
               text: content,
               summary: summary,
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
               summary: summary,
               format: 'json' }

    api_post params, current_user
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
  private

  def api_post(data, current_user)
    return {} if Features.disable_wiki_output?
    tokens = get_tokens(current_user)
    return tokens unless tokens['csrf_token']
    data[:token] = tokens.csrf_token

    # Make the request
    response = tokens.access_token.post(@api_url, data)
    response_data = JSON.parse(response.body)
    WikiResponse.capture(response_data, current_user: current_user,
                                        post_data: data,
                                        type: 'edit')
    response_data
  end

  def get_tokens(current_user)
    return { status: 'no current user' } unless current_user
    @access_token = oauth_access_token(current_user)
    get_token = @access_token.get("#{@api_url}?action=query&meta=tokens&format=json")

    token_response = JSON.parse(get_token.body)
    WikiResponse.capture(token_response, current_user: current_user,
                                         type: 'tokens')
    return { status: 'failed' } unless token_response.key?('query')
    OpenStruct.new(
      csrf_token: token_response['query']['tokens']['csrftoken'],
      access_token: @access_token
    )
  end

  def oauth_consumer
    OAuth::Consumer.new ENV['wikipedia_token'],
                        ENV['wikipedia_secret'],
                        client_options: {
                          site: "https://#{@wiki.language}.#{@wiki.project}.org"
                        }
  end

  def oauth_access_token(current_user)
    OAuth::AccessToken.new oauth_consumer,
                           current_user.wiki_token,
                           current_user.wiki_secret
  end
end
