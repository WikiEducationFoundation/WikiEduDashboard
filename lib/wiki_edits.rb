require "#{Rails.root}/lib/wiki_response"

#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  ################
  # Entry points #
  ################
  def self.oauth_credentials_valid?(current_user)
    get_tokens(current_user)
    current_user.wiki_token != 'invalid'
  end

  def self.notify_untrained(course_id, current_user)
    course = Course.find(course_id)
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
                          extra: { sender: current_user.wiki_id,
                                   course_name: course.slug,
                                   untrained_count: untrained_users.count }
  end

  def self.update_assignments(current_user, course)
    grouped_assignments = assignments_grouped_by_article_title(course)
    grouped_assignments.each do |title, assignments_for_same_title|
      update_assignments_for_title(current_user,
                                   title,
                                   assignments_for_same_title,
                                   course)
    end
  end

  def self.remove_assignment(current_user, assignment)
    article_title = assignment.article_title
    other_assignments_for_same_course_and_title = assignment.sibling_assignments
    course = assignment.course

    update_assignments_for_title(current_user,
                                 article_title,
                                 other_assignments_for_same_course_and_title,
                                 course)
  end

  def self.update_assignments_for_title(current_user, title, assignments_for_same_title, course)
    require './lib/wiki_assignment_output'

    # TODO: i18n of talk namespace
    if title[0..4] == 'Talk:'
      talk_title = title
    else
      talk_title = "Talk:#{title.tr(' ', '_')}"
    end

    course_page = course.wiki_title
    page_content = WikiAssignmentOutput
                   .build_talk_page_update(title,
                                           talk_title,
                                           assignments_for_same_title,
                                           course_page)

    return if page_content.nil?
    course_title = course.title
    summary = "Update [[#{course_page}|#{course_title}]] assignment details"
    post_whole_page(current_user, talk_title, page_content, summary)
  end

  def self.notify_user(sender, recipient, message)
    add_new_section(sender, recipient.talk_page, message)
  end

  ###################
  # Helper methods #
  ###################

  def self.notify_users(current_user, recipient_users, message)
    recipient_users.each do |recipient|
      add_new_section(current_user, recipient.talk_page, message)
    end
  end

  def self.assignments_grouped_by_article_title(course)
    course.assignments.group_by(&:article_title)
  end

  ####################
  # Basic edit types #
  ####################

  def self.post_whole_page(current_user, page_title, content, summary = nil)
    params = { action: 'edit',
               title: page_title,
               text: content,
               summary: summary,
               format: 'json' }

    api_post params, current_user
  end

  def self.add_new_section(current_user, page_title, message)
    params = { action: 'edit',
               title: page_title,
               section: 'new',
               sectiontitle: message[:sectiontitle],
               text: message[:text],
               summary: message[:summary],
               format: 'json' }

    api_post params, current_user
  end

  def self.add_to_page_top(page_title, current_user, content, summary)
    params = { action: 'edit',
               title: page_title,
               prependtext: content,
               summary: summary,
               format: 'json' }

    api_post params, current_user
  end

  ###############
  # API methods #
  ###############
  class << self
    private

    def api_post(data, current_user)
      return {} if ENV['disable_wiki_output'] == 'true'
      tokens = get_tokens(current_user)
      return tokens unless tokens['csrf_token']
      data.merge! token: tokens.csrf_token
      language = ENV['wiki_language']
      url = "https://#{language}.wikipedia.org/w/api.php"

      # Make the request
      response = tokens.access_token.post(url, data)
      response_data = JSON.parse(response.body)
      WikiResponse.capture(response_data, current_user: current_user,
                                          post_data: data,
                                          type: 'edit')
      response_data
    end

    def get_tokens(current_user)
      return { status: 'no current user' } unless current_user
      lang = ENV['wiki_language']
      @consumer = oauth_consumer(lang)
      @access_token = oauth_access_token(@consumer, current_user)
      # rubocop:disable Metrics/LineLength
      get_token = @access_token.get("https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json")
      # rubocop:enable Metrics/LineLength

      token_response = JSON.parse(get_token.body)
      WikiResponse.capture(token_response, current_user: current_user,
                                           type: 'tokens')
      return { status: 'failed' } unless token_response.key?('query')
      OpenStruct.new(
        csrf_token: token_response['query']['tokens']['csrftoken'],
        access_token: @access_token
      )
    end

    def oauth_consumer(lang)
      OAuth::Consumer.new ENV['wikipedia_token'],
                          ENV['wikipedia_secret'],
                          client_options: {
                            site: "https://#{lang}.wikipedia.org"
                          }
    end

    def oauth_access_token(consumer, current_user)
      OAuth::AccessToken.new consumer,
                             current_user.wiki_token,
                             current_user.wiki_secret
    end
  end
end
