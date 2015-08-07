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
    announcement_page = Figaro.env.course_announcement_page
    dashboard_url = Figaro.env.dashboard_url
    course_page_url = "http://#{dashboard_url}/courses/#{course.slug}"
    # rubocop:disable Metrics/LineLength
    announcement = "I have created a new course at #{dashboard_url}, [#{course_page_url} #{course.title}]. If you'd like to see more details about my course, check out my course page.--~~~~"
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

    dashboard_url = Figaro.env.dashboard_url
    summary = "Updating course from #{dashboard_url}"

    post_whole_page(current_user, wiki_title, wiki_text, summary)
  end

  def self.update_assignments(current_user, course, assignments=nil, delete=false)
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

    dashboard_url = Figaro.env.dashboard_url

    assignment_titles.each do |title, title_assignments|
      talk_title = "Talk:#{title.gsub(' ', '_')}"
      page_content = Wiki.get_page_content talk_title
      return if page_content.nil?

      # Get all assignments for this article/course
      siblings = title_assignments.select { |a| !a['deleted'] }

      # Build new tag
      tag_course = course.wiki_title
      a_ids = siblings.select { |a| a['role'] == 0 }.map { |a| a['user_id'] }
      tag_a = User.where(id: a_ids).pluck(:wiki_id)
              .map { |wiki_id| "[[User:#{wiki_id}|#{wiki_id}]]" }.join(', ')
      r_ids = siblings.select { |a| a['role'] == 1 }.map { |a| a['user_id'] }
      tag_r = User.where(id: r_ids).pluck(:wiki_id)
              .map { |wiki_id| "[[User:#{wiki_id}|#{wiki_id}]]" }.join(', ')
      new_tag = "{{#{dashboard_url} assignment | course = #{tag_course}"
      new_tag += " | assignments = #{tag_a}" unless tag_a.blank?
      new_tag += " | reviewers = #{tag_r}" unless tag_r.blank?
      new_tag += ' }}'

      # Return if tag already exists on page
      return if page_content.include? new_tag

      # Check for existing tags and replace
      old_tag_ex = "{{course assignment | course = #{course.wiki_title}"
      new_tag_ex = "{{#{dashboard_url} assignment | course = #{course.wiki_title}"
      if siblings.empty?
        page_content.gsub!(/#{Regexp.quote(old_tag_ex)}[^\}]*\}\}[\n]?/, '')
        page_content.gsub!(/#{Regexp.quote(new_tag_ex)}[^\}]*\}\}[\n]?/, '')
      else
        page_content.gsub!(/#{Regexp.quote(old_tag_ex)}[^\}]*\}\}/, new_tag)
        page_content.gsub!(/#{Regexp.quote(new_tag_ex)}[^\}]*\}\}/, new_tag)
      end

      # Add new tag at top (if there wasn't an existing tag already)
      if !page_content.include?(new_tag) && !siblings.empty?
        if page_content[0..1] == '{{' # Append after existing tags
          page_content.sub!(/\}\}(?!\n\{\{)/, "}}\n#{new_tag}")
        else # Add the tag to the top of the page
          page_content = "#{new_tag}\n\n#{page_content}"
        end
      end

      # Do not update page if nothing has chnged
      # return unless page_content.include? new_tag

      # Save the changed content to Wikipedia
      summary = "Update #{tag_course} assignment details"
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

      body = JSON.parse(get_token.body)
      if body.key? 'error'
        raise Exception.new body['error']['info']
      end

      token_response = JSON.parse(get_token.body)
      OpenStruct.new(
        csrf_token: token_response['query']['tokens']['csrftoken'],
        access_token: @access_token
      )
    rescue Exception => e
      Rails.logger.error "Authentication error: #{e}"
      Raven.capture_exception e, level: 'warning'
    end

    def api_post(data, tokens)
      return if Figaro.env.disable_wiki_output == 'true'
      language = Figaro.env.wiki_language
      url = "https://#{language}.wikipedia.org/w/api.php"

      # Make the request
      response = tokens.access_token.post(url, data)
      response_data = JSON.parse(response.body)
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

      unless response_data['edit']['result'] == 'Success'
        raise StandardError.new response_data['error']['code']
      end
      return response
    rescue StandardError => e
      Rails.logger.error "Edit error: #{e}"
      Raven.capture_exception e, level: 'warning',
                                 extra: { username: current_user.id,
                                          response_data: response_data }
    end
  end
end
