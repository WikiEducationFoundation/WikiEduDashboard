#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  def self.notify_untrained(course_id, current_user)
    course = Course.find(course_id)
    untrained_users = course.users.role('student').where(trained: false)

    message = { sectiontitle: I18n.t('wiki_edits.notify_untrained.header'),
                text: I18n.t('wiki_edits.notify_untrained.message'),
                summary: I18n.t('wiki_edits.notify_untrained.summary') }

    notify_students(course_id, current_user, untrained_users, message)

    # We want to see how much this specific feature gets used, so we send it
    # to Sentry.
    Raven.capture_message 'WikiEdits.notify_untrained',
                          level: 'info',
                          culprit: 'WikiEdits.notify_untrained',
                          extra: { sender: current_user.wiki_id,
                                   course_name: course.slug,
                                   untrained_count: untrained_users.count }
  end

  def self.notify_students(course_id, current_user, recipient_users, message)
    @course = Course.find(course_id)
    tokens = WikiEdits.tokens(current_user)

    recipient_users.each do |recipient|
      params = { action: 'edit',
                 title: "User_talk:#{recipient.wiki_id}",
                 section: 'new',
                 sectiontitle: message[:sectiontitle],
                 text: message[:text],
                 summary: message[:summary],
                 format: 'json',
                 token: tokens.csrf_token }

      WikiEdits.api_post params, tokens
    end
  end

  def self.enroll_in_course(current_user, course, role = 0)
    tokens = WikiEdits.tokens(current_user)
    template = "{{student editor|course = [[#{course.wiki_title}]] }}\n"
    params = { action: 'edit',
               title: "User:#{current_user.wiki_id}",
               prependtext: template,
               summary: "I am enrolled in [[#{course.wiki_title}]].",
               format: 'json',
               token: tokens.csrf_token }

    WikiEdits.api_post params, tokens
  end

  def self.get_wiki_top_section(course_page_slug, current_user, talk_page = true)
    tokens = WikiEdits.tokens(current_user)
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

    response = WikiEdits.api_post params, tokens
    puts response.body
    response.body
  end

  def self.update_course_talk(course, current_user, content, clear = false)
    require './lib/wiki_course_output'
    @course = course
    return unless current_user.wiki_id? && @course.slug?
    return if content[:text] == ''
    tokens = WikiEdits.tokens(current_user)

    if content[:contenttype] == 'markdown'
      text = WikiCourseOutput.markdown_to_mediawiki(content[:text])
    else
      text = content[:text]
    end
    course_talk_prefix = Figaro.env.course_talk_prefix
    course_talk_page_title = content[:pagetitle] || "#{course_talk_prefix}/#{@course.slug}"
    section = content[:section]
    params = { action: 'edit',
               title: course_talk_page_title,
               section: section,
               text: text,
               format: 'json',
               token: tokens.csrf_token }

    WikiEdits.api_post params, tokens
  end

  def self.update_course(course, current_user, delete = false)
    require './lib/wiki_course_output'

    return if Figaro.env.disable_wiki_output == 'true'
    @course = course
    return unless current_user.wiki_id? && @course.slug?

    if delete == true
      wiki_text = ''
    else
      wiki_text = WikiCourseOutput.translate_course(@course)
    end

    tokens = WikiEdits.tokens(current_user)
    course_prefix = Figaro.env.course_prefix
    wiki_title = "#{course_prefix}/#{@course.slug}"
    params = { action: 'edit',
               title: wiki_title,
               text: wiki_text,
               format: 'json',
               token: tokens.csrf_token }
    WikiEdits.api_post params, tokens
  end

  def self.tokens(current_user)
    language = Figaro.env.wiki_language
    @consumer = OAuth::Consumer.new Figaro.env.wikipedia_token,
                                    Figaro.env.wikipedia_secret,
                                    client_options: {
                                      site: "https://#{language}.wikipedia.org"
                                    }
    @access_token = OAuth::AccessToken.new @consumer,
                                           current_user.wiki_token,
                                           current_user.wiki_secret
    # rubocop:disable Metrics/LineLength
    get_token = @access_token.get("https://#{language}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json")
    # rubocop:enable Metrics/LineLength
    token_response = JSON.parse(get_token.body)

    OpenStruct.new(
      csrf_token: token_response['query']['tokens']['csrftoken'],
      access_token: @access_token
    )
  end

  def self.api_post(data, tokens)
    language = Figaro.env.wiki_language
    tokens.access_token.post("https://#{language}.wikipedia.org/w/api.php",
                             data)
  end
end
