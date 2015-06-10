require "#{Rails.root}/lib/wiki_output"

#= Class for making edits to Wikipedia via OAuth, using a user's credentials
class WikiEdits
  def self.notify_untrained(course_id, current_user)
    @course = Course.find(course_id)
    tokens = WikiEdits.tokens(current_user)

    @course.users.role('student').where(trained: false).each do |student|
      params = { action: 'edit',
                 title: "User_talk:#{student.wiki_id}",
                 section: 'new',
                 sectiontitle: I18n.t('wiki_edits.notify_untrained.header'),
                 text: I18n.t('wiki_edits.notify_untrained.message'),
                 summary: I18n.t('wiki_edits.notify_untrained.summary'),
                 format: 'json',
                 token: tokens.csrf_token }
      WikiEdits.api_get params, tokens
    end

    untrained_count = @course.users.role('student').where(trained: false).count
    Raven.capture_message 'WikiEdits.notify_untrained',
                          level: 'info',
                          culprit: 'WikiEdits.notify_untrained',
                          extra: { sender: current_user.wiki_id,
                                   course_name: @course.slug,
                                   untrained_count: untrained_count }
  end

  def self.notify_students(course_id, current_user, students, notification_type)
    @course = Course.find(course_id)
    tokens = WikiEdits.tokens(current_user)
    begin
      I18n.t!("wiki_edits.notify_#{notification_type}.header", :raise => true) 
    rescue I18n::MissingTranslationData
      return
    end
    section_title = I18n.t("wiki_edits.notify_#{notification_type}.header") + " | #{@course.title}"
    students.each do |student|
      params = { action: 'edit',
                 title: "User_talk:#{student.wiki_id}",
                 section: 'new',
                 sectiontitle: section_title,
                 text: I18n.t("wiki_edits.notify_#{notification_type}.message"),
                 summary: I18n.t("wiki_edits.notify_#{notification_type}.summary"),
                 format: 'json',
                 token: tokens.csrf_token }
      WikiEdits.api_get params, tokens
    end
    Raven.capture_message 'WikiEdits.notify_students',
                          level: 'info',
                          culprit: 'WikiEdits.notify_students',
                          extra: { sender: current_user.wiki_id,
                                   course_name: @course.slug,
                                   notification_type: notification_type }
  end

  def self.update_course(course, current_user, delete = false)
    @course = course
    if delete == true
      wiki_text = ''
    else
      wiki_text = WikiOutput.translate_course(@course, current_user)
    end
    tokens = WikiEdits.tokens(current_user)
    return unless current_user.wiki_id? && @course.slug?
    course_prefix = Figaro.env.course_prefix
    wiki_title = "#{course_prefix}/#{@course.slug}"
    params = { action: 'edit',
               title: wiki_title,
               text: wiki_text,
               format: 'json',
               token: tokens.csrf_token }
    WikiEdits.api_get params, tokens
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

  def self.api_get(data, tokens)
    language = Figaro.env.wiki_language
    tokens.access_token.post("https://#{language}.wikipedia.org/w/api.php",
                             data)
  end
end
