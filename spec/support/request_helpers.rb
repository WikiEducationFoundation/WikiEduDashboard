# frozen_string_literal: true

#= Stubs for various requests
module RequestHelpers
  ##################
  # OAuth requests #
  ##################
  def stub_token_request
    fake_tokens = '{"query":{"tokens":{"csrftoken":"faketoken+\\\\"}}}'
    lang = ENV['wiki_language']
    url = "https://#{lang}.wikipedia.org/w/api.php?action=query&meta=tokens&format=json&type=csrf"
    stub_request(:get, url)
      .to_return(status: 200, body: fake_tokens, headers: {})
  end

  def stub_account_creation_token_request(wiki: nil)
    fake_tokens = '{"query":{"tokens":{"createaccounttoken":"faketoken+\\\\"}}}'
    lang = wiki&.language || ENV['wiki_language']
    params_url = 'action=query&meta=tokens&format=json&type=createaccount'
    url = "https://#{lang}.wikipedia.org/w/api.php?#{params_url}"
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
    wikimedia_error = '<!DOCTYPE html><html lang=en><meta charset=utf-8>'\
                      '<title>Wikimedia Error</title></html>'
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

  def stub_account_creation(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    success = '{"createaccount":{"status":"PASS", "username":"Ragesock"}}'
    lang = wiki&.language || ENV['wiki_language']
    stub_request(:post, /.*#{lang}.wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_userexists(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "username":"Ragetest 99", "messagecode": "userexists"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_unexpected(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"username":"Ragetest 99"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_throttle(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "messagecode":"acct_creation_throttle_hit"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
  end

  def stub_account_creation_failure_captcha(wiki: nil)
    # Stub out the creation of accounts at Wikipedia
    # First the request for edit tokens for a user
    stub_account_creation_token_request(wiki:)

    # Then the account creation request itself
    failure = '{"createaccount":{"status":"FAIL",
                                 "messagecode":"captcha-createaccount-fail"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})

    # After account creation, stub the query for user info for UserImporter
    stub_list_users_query
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

  # If there's only one instance of a blocked link, MediaWiki returns an array for matches.
  def stub_oauth_edit_spamblock
    stub_token_request
    failure = '{"error":{"code":"spamblacklist",
              "spamblacklist":{"matches":["youtu.be"]}}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: failure, headers: {})
  end

  # If there are multiple links hitting the filter, MediaWiki may return an object of matches.
  def stub_oauth_edit_spamblock_multiple
    stub_token_request
    failure = '{"error":{"code":"spamblacklist",
              "spamblacklist":{"matches":{"0":"ur1.ca","4":"bit.ly/foo"}}}}'
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
    success = '{"warnings":{"options":{"*":"Validation error for \'visualeditor-enable\': not a v'\
              'alid preference"}}, "options":"success"}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end

  ############################
  # MediaWiki query requests #
  ############################
  def stub_contributors_query
    response = String.new '{"continue":{"pccontinue":"2169951|5094","continue":"||"},
                 "query":{"normalized":[{"from":"User_talk:Ragesoss","to":"User talk:Ragesoss"}],
                 "pages":{"2169951":{"pageid":2169951,"ns":3,"title":"User talk:Ragesoss",
                 "anoncontributors":17,"contributors":[{"userid":584,"name":"Danny"}]}}}}'

    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: response, headers: {})
  end

  def stub_raw_action
    stub_request(:get, %r{.*wikipedia.org/w/index.php\?action=raw.*})
      .to_return(status: 200, body: String.new('[[wikitext]]'), headers: {})
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
      'es.wikipedia.org',
      'pt.wikipedia.org',
      'zh.wikipedia.org',
      'mr.wikipedia.org',
      'eu.wikipedia.org',
      'fa.wikipedia.org',
      'fr.wikipedia.org',
      'ru.wikipedia.org',
      'simple.wikipedia.org',
      'tr.wikipedia.org',
      'en.wiktionary.org',
      'es.wiktionary.org',
      'ta.wiktionary.org',
      'es.wikibooks.org',
      'en.wikibooks.org',
      'ar.wikibooks.org',
      'en.wikivoyage.org',
      'wikisource.org',
      'es.wikisource.org',
      'www.wikidata.org',
      'en.wikinews.org',
      'pl.wikiquote.org',
      'de.wikiversity.org',
      'commons.wikimedia.org',
      'de.wikipedia.org',
      'en.wikipedia.org',
      'gl.wikipedia.org',
      'nl.wikipedia.org',
      'sv.wikipedia.org',
      'uk.wikipedia.org'
    ]

    wikis.each do |wiki|
      stub_request(:get, "https://#{wiki}/w/api.php?action=query&format=json&meta=siteinfo")
        .to_return(status: 200,
                   body: "{\"query\":{\"general\":{\"servername\":\"#{wiki}\"}}}",
                   headers: {})
    end
  end

  def stub_block_log_query
    response =
      '{"batchcomplete":"",
        "continue":{"lecontinue":"20180821221509|92647450","continue":"-||"},
        "query":{"logevents":[
          {"logid":92647503,
          "ns":2,
          "title":"User:Verdantpowerinc",
          "pageid":0,
          "logpage":0,
          "params":{"duration":"infinite","flags":["noautoblock"]},
          "type":"block",
          "action":"block",
          "user":"Drmies",
          "timestamp":"2018-08-21T22:19:01Z",
          "comment":"{{uw-softerblock}} <!-- Promotional username, soft block -->"}]}}'

    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: response, headers: {})
  end
end
