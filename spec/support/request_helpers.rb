module RequestHelpers
  def stub_oauth_edit
    # Stub out the posting of content to Wikipedia
    # First the request for edit tokens for a user
    fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"faketoken+\\\\\"}}}"
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: fake_tokens, headers: {})
    # Then the edit request itself
    success = '{"edit"=>
                {"result"=>"Success",
                 "pageid"=>11543696,
                 "title"=>"User:Ragesock",
                 "contentmodel"=>"wikitext",
                 "oldrevid"=>671572777,
                 "newrevid"=>674946741,
                 "newtimestamp"=>"2015-08-07T05:27:43Z"}}'
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: success, headers: {})
  end
end
