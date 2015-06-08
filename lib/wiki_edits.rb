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

  def self.save_course(course, current_user)
    @course = course
    wikitext = WikiOutput.translate_course(@course)
    tokens = WikiEdits.tokens(current_user)
    return unless current_user.wiki_id? && @course.slug?
    update_slug = "User:#{current_user.wiki_id}/#{@course.slug}" 
    params = { action: 'edit',
               title: update_slug,
               text: wikitext,
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
