require "#{Rails.root}/lib/wiki_response"

#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  ################
  # Entry points #
  ################
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

  # This method both posts to the instructor's userpage and also makes a public
  # announcement of a newly submitted course at the course announcement page.
  def self.announce_course(course, current_user, instructor = nil)
    instructor ||= current_user
    course_title = course.wiki_title
    user_page = "User:#{instructor.wiki_id}"
    template = "{{course instructor|course = [[#{course_title}]] }}\n"
    summary = "New course announcement: [[#{course_title}]]."

    # Add template to userpage to indicate instructor role.
    add_to_page_top(user_page, current_user, template, summary)

    # Announce the course on the Education Noticeboard or equivalent.
    announcement_page = ENV['course_announcement_page']
    dashboard_url = ENV['dashboard_url']
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course — #{course.title} — at #{dashboard_url}/courses/#{course.slug}. If you'd like to see more details about my course, check out my course page.--~~~~"
    section_title = "New course announcement: [[#{course_title}]] (instructor: [[User:#{instructor.wiki_id}]])"
    # rubocop:enable Metrics/LineLength
    message = { sectiontitle: section_title,
                text: announcement,
                summary: summary }

    add_new_section(current_user, announcement_page, message)
  end

  def self.enroll_in_course(course, current_user)
    # Add a template to the user page
    course_title = course.wiki_title
    template = "{{student editor|course = [[#{course_title}]] }}\n"
    user_page = "User:#{current_user.wiki_id}"
    summary = "I am enrolled in [[#{course_title}]]."
    add_to_page_top(user_page, current_user, template, summary)

    # Pre-create the user's sandbox
    # TODO: Do this more selectively, replacing the default template if
    # it is present.
    sandbox = user_page + '/sandbox'
    sandbox_template = '{{student sandbox}}'
    sandbox_summary = 'adding {{student sandbox}}'
    add_to_page_top(sandbox, current_user, sandbox_template, sandbox_summary)
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

    # Post the update
    response = post_whole_page(current_user, wiki_title, wiki_text, summary)

    # If it hit the spam blacklist, replace the offending links and try again.
    if response['edit']
      bad_links = response['edit']['spamblacklist']
      return response if bad_links.nil?
      bad_links = bad_links.split('|')
      safe_wiki_text = WikiCourseOutput
                       .substitute_bad_links(wiki_text, bad_links)
      post_whole_page(current_user, wiki_title, safe_wiki_text, summary)
    end
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

    def get_tokens(current_user)
      lang = ENV['wiki_language']
      @consumer = oauth_consumer(lang)
      @access_token = oauth_access_token(@consumer, current_user)
      # rubocop:disable Metrics/LineLength
      get_token = @access_token.get("https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json")
      # rubocop:enable Metrics/LineLength

      token_response = JSON.parse(get_token.body)
      WikiResponse.capture(token_response, current_user: current_user,
                                           type: 'tokens')
      return {} unless token_response.key?('query')
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

    def api_post(data, current_user)
      return {} if ENV['disable_wiki_output'] == 'true'
      tokens = get_tokens(current_user)
      return { status: 'failed' } if tokens['csrf_token'].nil?
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
  end
end
