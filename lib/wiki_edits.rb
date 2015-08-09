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

  def self.update_assignments(current_user,
                              course,
                              assignments = nil,
                              delete = false)

    assignment_titles = assignments_by_article(course, assignments, delete)
    course_page = course.wiki_title

    assignment_titles.each do |title, title_assignments|
      # FIXME: make sure each title is actually a mainspace page. If a talk page
      # or a page in another namespace is assigned, then this would post to
      # places that it shouldn't.
      talk_title = "Talk:#{title.gsub(' ', '_')}"

      initial_page_content = Wiki.get_page_content talk_title
      # We only want to add assignment tags to non-existant talk pages if the
      # article page actually exists.
      if initial_page_content.nil?
        next if Wiki.get_page_content(title).nil?
        initial_page_content = ''
      end

      # Limit it to live assignments for this article-course
      title_assignments = title_assignments.select { |a| !a['deleted'] }

      course_assignments_tag = assignments_tag(course_page, title_assignments)
      page_content = build_assignment_page_content(title,
                                                   talk_title,
                                                   course_assignments_tag,
                                                   course_page,
                                                   initial_page_content)
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

  def self.assignments_by_article(course, assignments, delete)
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

  def self.assignments_tag(course_page, title_assignments)
    return '' if title_assignments.empty?

    # Make a list of the assignees, role 0
    tag_assigned = build_wikitext_user_list(title_assignments, 0)
    # Make a list of the reviwers, role 1
    tag_reviewing = build_wikitext_user_list(title_assignments, 1)

    # Build new tag
    # NOTE: If the format of this tag gets changed, then the dashboard may
    # post duplicate tags for the same page, unless we update the way that
    # we check for the presense of existging tags to account for both the new
    # and old formats.
    dashboard_url = Figaro.env.dashboard_url
    tag = "{{#{dashboard_url} assignment | course = #{course_page}"
    tag += " | assignments = #{tag_assigned}" unless tag_assigned.blank?
    tag += " | reviewers = #{tag_reviewing}" unless tag_reviewing.blank?
    tag += ' }}'

    tag
  end

  # This method creates updated wikitext for an article talk page, for when
  # the set of assigned users for the article for a single course changes.
  # The strategy here is to only update the tag for one course at a time, so
  # that the user who updates the assignments for a course only introduces data
  # for that course. We also want to make as minimal a change as possible, and
  # to make sure that we're not disrupting the format of existing content.
  def self.build_assignment_page_content(title,
                                         talk_title,
                                         new_tag,
                                         course_page,
                                         page_content)

    dashboard_url = Figaro.env.dashboard_url
    # Return if tag already exists on page
    unless new_tag.blank?
      return nil if page_content.include? new_tag
    end

    # Check for existing tags and replace
    old_tag_ex = "{{course assignment | course = #{course_page}"
    new_tag_ex = "{{#{dashboard_url} assignment | course = #{course_page}"
    page_content.gsub!(/#{Regexp.quote(old_tag_ex)}[^\}]*\}\}/, new_tag)
    page_content.gsub!(/#{Regexp.quote(new_tag_ex)}[^\}]*\}\}/, new_tag)

    # Add new tag at top (if there wasn't an existing tag already)
    if !page_content.include?(new_tag) && !new_tag.blank?
      # FIXME: Allow whitespace before the beginning of the first template.
      if page_content[0..1] == '{{' # Append after existing tags
        page_content.sub!(/\}\}(?!\n\{\{)/, "}}\n#{new_tag}")
      else # Add the tag to the top of the page
        page_content = "#{new_tag}\n\n#{page_content}"
      end
    end

    page_content
  end

  def self.build_wikitext_user_list(siblings, role)
    user_ids = siblings.select { |a| a['role'] == role }
               .map { |a| a['user_id'] }
    User.where(id: user_ids).pluck(:wiki_id)
      .map { |wiki_id| "[[User:#{wiki_id}|#{wiki_id}]]" }.join(', ')
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
        raise StandardError.new body['error']['info']
      end

      token_response = JSON.parse(get_token.body)
      OpenStruct.new(
        csrf_token: token_response['query']['tokens']['csrftoken'],
        access_token: @access_token
      )
    rescue StandardError => e
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

      if response_data['error']
        raise StandardError.new response_data['error']['code']
      end
      return response
    rescue StandardError => e
      Rails.logger.error "Edit error: #{e}"
      Raven.capture_exception e, level: 'warning',
                                 extra: { response_data: response_data }
    end
  end
end
