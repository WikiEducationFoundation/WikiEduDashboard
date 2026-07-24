# frozen_string_literal: true

require 'rails_helper'

describe 'LtiServiceSession#post_score', type: :service do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'p', lms_family: 'canvas',
      lms_context_id: 'c', lms_resource_link_id: 'r',
      ltiaas_service_credentials: 'svc-key'
    )
  end
  let(:lineitem_id) { 'https://lms.example.com/li/abc' }
  let(:scores_url) do
    "https://#{domain}/api/lineitems/#{CGI.escape(lineitem_id)}/scores"
  end

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { LtiServiceSession.new(binding) }

  it 'POSTs the LTI Advantage score body with the SERVICE-AUTH-V1 header' do
    stub = stub_request(:post, scores_url)
           .with(headers: { 'Authorization' => 'SERVICE-AUTH-V1 api-key:svc-key' },
                 body: hash_including(userId: 'lti-alice', scoreGiven: 1.0,
                                      scoreMaximum: 1.0,
                                      activityProgress: 'Completed',
                                      gradingProgress: 'FullyGraded'))
           .to_return(status: 204, body: '', headers: {})

    service.post_score(lineitem_id: lineitem_id, user_lti_id: 'lti-alice',
                       score_given: 1.0)
    expect(stub).to have_been_requested
  end

  it 'includes the comment field when provided' do
    stub = stub_request(:post, scores_url)
           .with(body: hash_including(comment: 'Bibliography: https://en.wikipedia.org/wiki/User:Alice/sandbox'))
           .to_return(status: 204, body: '')

    service.post_score(lineitem_id: lineitem_id, user_lti_id: 'lti-alice',
                       score_given: 1.0,
                       comment: 'Bibliography: https://en.wikipedia.org/wiki/User:Alice/sandbox')
    expect(stub).to have_been_requested
  end

  it 'omits the comment field when not provided' do
    stub = stub_request(:post, scores_url)
           .with { |req| !JSON.parse(req.body).key?('comment') }
           .to_return(status: 204, body: '')

    service.post_score(lineitem_id: lineitem_id, user_lti_id: 'lti-alice',
                       score_given: 0.5)
    expect(stub).to have_been_requested
  end
end
