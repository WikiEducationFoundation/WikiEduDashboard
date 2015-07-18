module RequestHelpers
  def stub_oauth_edit
    # Stub out the posting of content to Wikipedia
    # First the request for edit tokens for a user
    fake_tokens = "{\"query\":{\"tokens\":{\"csrftoken\":\"faketoken+\\\\\"}}}"
    stub_request(:get, /.*wikipedia.*/)
      .to_return(status: 200, body: fake_tokens, headers: {})
    # Then the edit request itself
    stub_request(:post, /.*wikipedia.*/)
      .to_return(status: 200, body: 'success', headers: {})
  end
end
