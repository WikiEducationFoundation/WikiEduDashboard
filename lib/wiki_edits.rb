#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  ################
  # Entry points #
  ################
  def self.notify_untrained(course_id, current_user)
    course = Course.find(course_id)
    untrained_users = course.users.role('student').where(trained: false)

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

  # This method both posts to the instructor's userpage and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def self.announce_course(course, current_user, instructor = nil)
    instructor ||= current_user
    user_page = "User:#{instructor.wiki_id}"
    template = "{{course instructor|course = [[#{course.wiki_title}]] }}\n"
    summary = "New course announcement: [[#{course.wiki_title}]]."

    # Add template to userpage to indicate instructor role.
    add_to_page_top(user_page, current_user, template, summary)

    # Announce the course on the Education Noticeboard or equivalent.
    announcement_page = ENV['course_announcement_page']
    dashboard_url = ENV['dashboard_url']
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course at #{dashboard_url}, {{#{dashboard_url} course link|#{course.slug}|#{course.title}}}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{course.wiki_title}]] (instructor: [[User:#{instructor.wiki_id}]])"
    # rubocop:enable Metrics/LineLength
    message = { sectiontitle: section_title,
                text: announcement,
                summary: summary }

    add_new_section(current_user, announcement_page, message)
  end

  def self.enroll_in_course(course, current_user)
    template = "{{student editor|course = [[#{course.wiki_title}]] }}\n"
    user_page = "User:#{current_user.wiki_id}"
    summary = "I am enrolled in [[#{course.wiki_title}]]."

    add_to_page_top(user_page, current_user, template, summary)
  end

  def self.update_course(course, current_user, delete = false)
    require './lib/wiki_course_output'

    return unless current_user.wiki_id? && course.submitted && course.slug?

    if delete == true
      wiki_text = ''
    else
      wiki_text = WikiCourseOutput.translate_course(course)
    end

    course_prefix = ENV['course_prefix']
    wiki_title = "#{course_prefix}/#{course.slug}"

    dashboard_url = ENV['dashboard_url']
    summary = "Updating course from #{dashboard_url}"

    post_whole_page(current_user, wiki_title, wiki_text, summary)
  end

  def self.update_assignments(current_user,
                              course,
                              assignments = nil,
                              delete = false)
    require './lib/wiki_assignment_output'

    assignment_titles = assignments_by_article(course, assignments, delete)
    course_page = course.wiki_title

    assignment_titles.each do |title, title_assignments|
      # TODO: i18n of talk namespace
      if title[0..4] == 'Talk:'
        talk_title = title
      else
        talk_title = "Talk:#{title.gsub(' ', '_')}"
      end

      page_content = WikiAssignmentOutput
                     .build_talk_page_update(title,
                                             talk_title,
                                             title_assignments,
                                             course_page)

      next if page_content.nil?
      summary = "Update #{course_page} assignment details"
      post_whole_page(current_user, talk_title, page_content, summary)
    end
  end

  ###################
  # Helper methods #
  ###################

  def self.notify_users(current_user, recipient_users, message)
    recipient_users.each do |recipient|
      user_talk_page = "User_talk:#{recipient.wiki_id}"
      add_new_section(current_user, user_talk_page, message)
    end
  end

  def self.assignments_by_article(course, assignments = nil, delete = false)
    if assignments.nil?
      assignment_titles = course.assignments.group_by(&:article_title).as_json
    else
      assignment_titles = assignments.group_by { |a| a['article_title'] }
    end

    if delete
      assignment_titles.each do |_title, title_assignments|
        title_assignments.each do |assignment|
          assignment['deleted'] = true
        end
      end
    end
    assignment_titles
  end

  ####################
  # Basic edit types #
  ####################

  def self.post_whole_page(current_user, page_title, content, summary = nil)
    tokens = get_tokens(current_user)
    params = { action: 'edit',
               title: page_title,
               text: content,
               summary: summary,
               format: 'json',
               token: tokens.csrf_token }

    api_post params, tokens, current_user
  end

  def self.add_new_section(current_user, page_title, message)
    tokens = get_tokens(current_user)
    params = { action: 'edit',
               title: page_title,
               section: 'new',
               sectiontitle: message[:sectiontitle],
               text: message[:text],
               summary: message[:summary],
               format: 'json',
               token: tokens.csrf_token }

    api_post params, tokens, current_user
  end

  def self.add_to_page_top(page_title, current_user, content, summary)
    tokens = get_tokens(current_user)
    params = { action: 'edit',
               title: page_title,
               prependtext: content,
               summary: summary,
               format: 'json',
               token: tokens.csrf_token }

    api_post params, tokens, current_user
  end

  ###############
  # API methods #
  ###############
  class << self
    private

    def get_tokens(current_user)
      lang = ENV['wiki_language']
      @consumer = OAuth::Consumer.new ENV['wikipedia_token'],
                                      ENV['wikipedia_secret'],
                                      client_options: {
                                        site: "https://#{lang}.wikipedia.org"
                                      }
      @access_token = OAuth::AccessToken.new @consumer,
                                             current_user.wiki_token,
                                             current_user.wiki_secret
      # rubocop:disable Metrics/LineLength
      get_token = @access_token.get("https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json")
      # rubocop:enable Metrics/LineLength

      token_response = JSON.parse(get_token.body)
      check_api_response(token_response, current_user: current_user,
                                         type: 'tokens')

      OpenStruct.new(
        csrf_token: token_response['query']['tokens']['csrftoken'],
        access_token: @access_token
      )
    end

    def api_post(data, tokens, current_user)
      return if ENV['disable_wiki_output'] == 'true'
      language = ENV['wiki_language']
      url = "https://#{language}.wikipedia.org/w/api.php"

      # Make the request
      response = tokens.access_token.post(url, data)
      response_data = JSON.parse(response.body)
      check_api_response(response_data, current_user: current_user,
                                        post_data: data,
                                        type: 'edit')

      response
    end

    def check_api_response(response_data, opts={})
      current_user = opts[:current_user]
      post_data = opts[:post_data]
      type = opts[:type]

      if current_user
        username = current_user.wiki_id
      else
        username = nil
      end
      # A successful edit will have response data like this:
      # {"edit"=>
      #   {"result"=>"Success",
      #    "pageid"=>11543696,
      #    "title"=>"User:Ragesock",
      #    "contentmodel"=>"wikitext",
      #    "oldrevid"=>671572777,
      #    "newrevid"=>674946741,
      #    "newtimestamp"=>"2015-08-07T05:27:43Z"}}
      #
      # A failed edit will have a response like this:
      # {"servedby"=>"mw1135",
      #  "error"=>
      #    {"code"=>"protectedpage",
      #     "info"=>"The \"templateeditor\" right is required to edit this page",
      #     "*"=>"See https://en.wikipedia.org/w/api.php for API usage"}}
      if response_data['error']
        title = "Failed #{type}"
        level = 'warning'
      else
        title = "Successful #{type}"
        level = 'info'
      end
      Raven.capture_message title,
                            level: level,
                            tags: { username: username,
                                    action_type: type },
                            extra: { response_data: response_data,
                                     post_data: post_data,
                                     current_user: current_user }
    end
  end
end
