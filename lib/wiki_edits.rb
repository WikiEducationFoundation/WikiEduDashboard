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
  # announcment of a newly submitted course at the course announcement page.
  def self.announce_course(course, current_user, instructor = nil)
    instructor ||= current_user
    user_page = "User:#{instructor.wiki_id}"
    template = "{{course instructor|course = [[#{course.wiki_title}]] }}\n"
    summary = "New course announcement: [[#{course.wiki_title}]]."

    # Add template to userpage to indicate instructor role.
    add_to_page_top(user_page, current_user, template, summary)

    # Announce the course on the Education Noticeboard or equivalent.
    announcement_page = Figaro.env.course_announcement_page
    course_page_url = "http://dashboard.wikiedu.org/courses/#{course.slug}"
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course at dashboard.wikiedu.org, [#{course_page_url} #{course.title}]. If you'd like to see more details about my course, check out my course page.--~~~~"
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

    course_prefix = Figaro.env.course_prefix
    wiki_title = "#{course_prefix}/#{course.slug}"

    summary = 'Updating course from dashboard.wikiedu.org'

    post_whole_page(current_user, wiki_title, wiki_text, summary)
  end

  ###################
  # Helpler methods #
  ###################

  def self.notify_users(current_user, recipient_users, message)
    recipient_users.each do |recipient|
      user_talk_page = "User_talk:#{recipient.wiki_id}"
      add_new_section(current_user, user_talk_page, message)
    end
  end

  def self.get_wiki_top_section(course_page_slug, current_user, talk_page = true)
    tokens = get_tokens(current_user)
    # if talk_page
    #   course_prefix = Figaro.env.course_talk_prefix
    # else
    #   course_prefix = Figaro.env.course_prefix
    # end
    # page_title = "#{course_page_slug}"
    puts course_page_slug
    params = { action: 'parse',
               page: course_page_slug,
               section: '0',
               prop: 'wikitext',
               format: 'json' }

    response = api_post params, tokens
    puts response.body
    response.body
  end

  ####################
  # Basic edit types #
  ####################

  def self.post_whole_page(current_user, page_title, content, summary = nil)
    tokens = get_tokens(current_user)
    cleanup(content)
    params = { action: 'edit',
               title: page_title,
               text: content,
               summary: summary,
               format: 'json',
               token: tokens.csrf_token }

    api_post params, tokens
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

    api_post params, tokens
  end

  def self.add_to_page_top(page_title, current_user, content, summary)
    tokens = get_tokens(current_user)
    params = { action: 'edit',
               title: page_title,
               prependtext: content,
               summary: summary,
               format: 'json',
               token: tokens.csrf_token }

    api_post params, tokens
  end

  ###############
  # API methods #
  ###############
  class << self
    private

    def get_tokens(current_user)
      lang = Figaro.env.wiki_language
      @consumer = OAuth::Consumer.new Figaro.env.wikipedia_token,
                                      Figaro.env.wikipedia_secret,
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

      OpenStruct.new(
        csrf_token: token_response['query']['tokens']['csrftoken'],
        access_token: @access_token
      )
    end

    def api_post(data, tokens)
      return if Figaro.env.disable_wiki_output == 'true'
      language = Figaro.env.wiki_language
      tokens.access_token.post("https://#{language}.wikipedia.org/w/api.php",
                               data)
    end

    #############
    # Utilities #
    #############
    def cleanup(content)
      # Clean up file URLS
      # TODO: Fence this, ensure usage of wikimedia commons?
      file_tags = content.scan(/\[\[File:[^\]]*\]\]/)
      file_tags.each do |file_tag|
        fixed_tag = file_tag.gsub /(?<=File:)[^\]]*\//, ''
        content.gsub! file_tag, fixed_tag
      end
    end
  end
end
