#= Reports message to Sentry about the success or failure of wiki edits
class WikiResponse
  ###############
  # Entry point #
  ###############
  def self.capture(response_data, opts={})
    current_user = opts[:current_user] || {}
    post_data = opts[:post_data]
    type = opts[:type]

    sorting_info = parse_api_response(response_data, type, current_user)
    Raven.capture_message sorting_info[:title],
                          level: sorting_info[:level],
                          tags: { username: current_user[:username],
                                  action_type: type },
                          extra: { response_data: response_data,
                                   post_data: post_data,
                                   current_user: current_user }
  end

  ###################
  # Parsing methods #
  ###################
  def self.parse_api_response(response_data, type, current_user)
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
    #
    # An edit stopped by the abuse filter will respond like this:
    # {"edit"=>
    #   {"result"=>"Failure",
    #    "code"=>"abusefilter-warning-email",
    #    "info"=>"Hit AbuseFilter: Adding emails in articles",
    #    "warning"=>"[LOTS OF HTML WARNING TEXT]"}}
    if response_data['error']
      title_and_level = parse_api_error_response(response_data, type, current_user)
    elsif response_data['edit']
      title_and_level = parse_api_edit_response(response_data, type)
    elsif response_data['query']
      title = "#{type} query"
      level = 'info'
      title_and_level = { title: title, level: level }
    else
      title = "Unknown response for #{type}"
      level = 'error'
      title_and_level = { title: title, level: level }
    end
    title_and_level
  end

  def self.parse_api_edit_response(response_data, type)
    edit_data = response_data['edit']
    if edit_data['result'] == 'Success'
      title = "Successful #{type}"
      level = 'info'
    else
      title = "Failed #{type}"
      title += ': CAPTCHA' if edit_data['captcha']
      title += ': spamblacklist' if edit_data['spamblacklist']
      code = response_data['edit']['code']
      title += ": #{code}" if edit_data['code']
      level = 'warning'
    end
    { title: title, level: level }
  end

  def self.parse_api_error_response(response_data, type, current_user)
    code = response_data['error']['code']

    # If the OAuth credentials are invalid, we need to flag this.
    # It gets handled by application controller.
    if code == 'mwoauth-invalid-authorization'
      current_user.update_attributes(wiki_token: 'invalid')
    end

    title = "Failed #{type}: #{code}"
    level = 'warning'
    { title: title, level: level }
  end
end
