#= Stubs for various requests
module RequestHelpers
  ##################
  # OAuth requests #
  ##################
  def stub_token_request
    fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"faketoken+\\\\\"}}}"
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: fake_tokens, headers: {})
  end

  def stub_token_request_failure
    token_error = '{"servedby":"mw1135","error":{"code":"foo","info":"bar"}}'
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: token_error, headers: {})
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
  ############################
  # MediaWiki query requests #
  ############################
  def stub_commons_503_error
    stub_request(:get, /.*commons.wikimedia.org.*/)
      .to_return(status: 503, body: '', headers: {})
  end
end
