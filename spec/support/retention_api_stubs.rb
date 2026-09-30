# frozen_string_literal: true

# Stubs for the two usercontribs queries RetentionStudentStats makes per student
# and wiki: the edit timeline (bounded by :ucend) and the pre-course edit count
# (not bounded), which is how the stub tells them apart.
module RetentionApiStubs
  # Builds a stub MediaWiki API response object for a list of edit Times.
  def response_for(times, continue: nil)
    contribs = times.map { |t| { 'timestamp' => t.utc.strftime('%Y-%m-%dT%H:%M:%SZ') } }
    instance_double(MediawikiApi::Response).tap do |response|
      allow(response).to receive(:data).and_return('usercontribs' => contribs)
      allow(response).to receive(:[]).with('continue').and_return(continue)
    end
  end

  # One page of a user's pre-course contributions, out of `total` of them.
  # Pages at 250 per response (the API may return fewer than the requested
  # max), so the stop-counting-at-the-threshold pagination gets exercised for
  # real.
  def prior_edits_response(total, params)
    offset = (params['uccontinue'] || params[:uccontinue]).to_i
    remaining = total - offset
    page = [remaining, 250].min
    continue = remaining > page ? { 'uccontinue' => (offset + page).to_s } : nil
    response_for([Time.zone.now] * page, continue:)
  end

  # Stubs WikiApi.new(wiki) for both queries. `contribs_by_user` maps
  # username => [Time, ...]; `prior_edits` maps username => edit count.
  def stub_wiki(wiki, contribs_by_user, prior_edits = {})
    api = instance_double(WikiApi)
    allow(WikiApi).to receive(:new).with(wiki).and_return(api)
    allow(api).to receive(:query) do |params|
      if params.key?(:ucend)
        response_for(contribs_by_user.fetch(params[:ucuser], []))
      else
        prior_edits_response(prior_edits.fetch(params[:ucuser], 0), params)
      end
    end
  end
end
