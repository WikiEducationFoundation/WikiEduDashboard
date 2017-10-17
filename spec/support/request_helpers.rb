# frozen_string_literal: true

#= Stubs for various requests
module RequestHelpers
  ##################
  # OAuth requests #
  ##################
  def stub_token_request
    fake_tokens = '{"query":{"tokens":{"csrftoken":"faketoken+\\\\"}}}'
    lang = ENV['wiki_language']
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json"
    stub_request(:get, url)
      .to_return(status: 200, body: fake_tokens, headers: {})
  end

  def stub_token_request_failure
    token_error = '{"servedby":"mw1135",
      "error": {"code":"mwoauth-invalid-authorization","info":"bar"}}'
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: token_error, headers: {})
  end

  def stub_wikimedia_error(code: 503)
    wikimedia_error = '<!DOCTYPE html><html lang=en><meta charset=utf-8><title>Wikimedia Error</title></html>'
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: code, body: wikimedia_error, headers: {})
  end

  def stub_oauth_edit_with_empty_response
    stub_token_request
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: '{}', headers: {})
  end

  def stub_oauth_edit
    # Stub out the posting of content to Wikipedia
    # First the request for edit tokens for a user
    stub_token_request
    # Then the edit request itself
    success = '{"edit":{"result":"Success","pageid":11543696,
              "title":"User:Ragesock","contentmodel":"wikitext",
              "oldrevid":671572777,"newrevid":674946741,
              "newtimestamp":"2015-08-07T05:27:43Z"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  def stub_oauth_edit_failure
    stub_token_request
    # Then the edit request itself
    failure = '{"servedby":"mw1135", "error":{"code":"protectedpage",
      "info":"The \"templateeditor\" right is required to edit this page",
      "*":"See https://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_edit_failure_blocked
    stub_token_request
    failure = '{"servedby":"mw1135", "error":{"code":"blocked",
      "info":"You have been blocked from editing.",
      "*":"See http://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_edit_failure_autoblocked
    stub_token_request
    failure = '{"servedby":"mw1135", "error":{"code":"autoblocked",
      "info":"Your IP address has been blocked automatically.",
      "*":"See http://en.wikipedia.org/w/api.php for API usage"}}'
    stub_request(:post, /.*wikipedia*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_edit_abusefilter
    stub_token_request
    # Then the edit request itself
    failure = '{"edit":{"result":"Failure","code":"abusefilter-warning-email",
              "info":"Hit AbuseFilter: Adding emails in articles",
              "warning":"LOTS OF WARNING TEXT"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_edit_spamblacklist
    stub_token_request
    failure = '{"edit":{"result":"Failure",
              "spamblacklist":"ur1.ca|bit.ly/foo"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_edit_captcha
    stub_token_request
    failure = '{"edit":{"result":"Failure","captcha":{"id":1234567,
      "mime":"image/png","type":"image",
      "url":"/w/index.php?title=Special:Captcha/image&wpCaptchaId=1234567"}}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  def stub_oauth_options_success
    stub_token_request
    success = '{"options":"success"}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  def stub_oauth_options_warning
    stub_token_request
    success = '{"warnings":{"options":{"*":"Validation error for \'visualeditor-enable\': not a valid preference"}}, "options":"success"}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  ############################
  # MediaWiki query requests #
  ############################
  def stub_contributors_query
    response = '{"continue":{"pccontinue":"2169951|5094","continue":"||"},
               "query":{"normalized":[{"from":"User_talk:Ragesoss","to":"User talk:Ragesoss"}],
               "pages":{"2169951":{"pageid":2169951,"ns":3,"title":"User talk:Ragesoss",
               "anoncontributors":17,"contributors":[{"userid":584,"name":"Danny"}]}}}}'

    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: response, headers: {})
  end

  def stub_raw_action
    stub_request(:get, %r{.*wikipedia.org/w/index.php\?action=raw.*})
      .to_return(status: 200, body: '[[wikitext]]', headers: {})
  end

  def stub_info_query
    stub_request(:get, /.*&prop=info.*/)
      .to_return(status: 200, body: '{}', headers: {})
  end

  def stub_list_users_query
    stub_request(:get, /.*list=users.*/)
      .to_return(status: 200, body: '{"users":[{"emailable":""}]}', headers: {})
  end

  def stub_list_users_query_with_no_email
    stub_request(:get, /.*list=users.*/)
      .to_return(status: 200, body: '{"users":[{}]}', headers: {})
  end

  def stub_wikipedia_503_error
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 503, body: '{}', headers: {})
  end

  def stub_commons_503_error
    stub_request(:get, /.*commons.wikimedia.org.*/)
      .to_return(status: 503, body: '', headers: {})
  end

  def stub_wiki_validation
    wikis = [
      'incubator.wikimedia.org',
      'en.wiktionary.org',
      'es.wiktionary.org',
      'es.wikipedia.org',
      'pt.wikipedia.org',
      'ta.wiktionary.org',
      'es.wikibooks.org',
      'ar.wikibooks.org',
      'en.wikivoyage.org',
      'wikisource.org',
      'www.wikidata.org'
    ]

    wikis.each do |wiki|
      stub_request(:get, "https://#{wiki}/w/api.php?action=query&format=json&meta=siteinfo")
        .to_return(status: 200, body: "{\"query\":{\"general\":{\"servername\":\"#{wiki}\"}}}", headers: {})
    end
  end

  ###################
  # Rocket.Chat API #
  ###################
  def stub_chat_login_success
    success_response = {
      'status' => 'success',
      'data': {
        'authToken' => 'fakeAuthToken',
        'userId' => 'chatIdForUser'
      }
    }
    stub_request(:post, /.*login/)
      .to_return(status: 200, body: success_response.to_json, headers: {})
  end

  def stub_chat_user_create_success
    success_response = {
      'success' => true,
      'user': {
        '_id': 'userId'
      }
    }
    stub_request(:post, /.*users.create/)
      .to_return(status: 200, body: success_response.to_json, headers: {})
  end

  def stub_chat_channel_create_success
    stub_chat_login_success # Admin login happens before channel creation
    success_response = {
      'success' => true,
      'group': {
        '_id': 'channelId'
      }
    }
    stub_request(:post, /.*groups.create/)
      .to_return(status: 200, body: success_response.to_json, headers: {})
  end

  def stub_add_user_to_channel_success
    # These happen before adding the user, if the user and room don't exist already.
    stub_chat_user_create_success
    stub_chat_channel_create_success
    success_response = {
      'success' => true
    }
    stub_request(:post, /.*groups.invite/)
      .to_return(status: 200, body: success_response.to_json, headers: {})
  end

  def stub_chat_error
    stub_request(:post, %r{.*/api/v1/.*})
      .to_return(status: 403, body: '{}', headers: {})
  end
end
