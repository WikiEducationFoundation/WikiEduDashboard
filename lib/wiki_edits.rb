class WikiEdits
  def self.notify_untrained(course_id, current_user)
    @course = Course.find(course_id)
    tokens = WikiEdits.tokens(current_user)

    @course.users.role('student').where(trained: false).each do |student|
      WikiEdits.api_get({
                          action: 'edit',
                          title: "User_talk:#{student.wiki_id}",
                          appendtext: 'You have not completed training',
                          summary: 'Training incomplete',
                          format: 'json',
                          token: tokens.csrf_token
                        }, tokens)
    end

    Raven.capture_message 'WikiEdits.notify_untrained',
      level: 'info',
      extra: {
        sender: current_user.wiki_id,
        course_name: @course.slug,
        untrained_count: @course.users.role('student')
                         .where(trained: false).count
      }
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
    get_token = @access_token.get("https://#{language}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json")
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
