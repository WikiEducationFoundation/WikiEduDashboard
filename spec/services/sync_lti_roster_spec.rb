# frozen_string_literal: true

require 'rails_helper'

describe SyncLtiRoster do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:course) do
    create(:course).tap { |c| c.campaigns << Campaign.first }
  end
  let(:binding) do
    LtiCourseBinding.create!(
      course: course,
      lms_id: 'platform-x', lms_family: 'canvas',
      lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key'
    )
  end
  let(:memberships_url) { "https://#{domain}/api/memberships" }

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  def stub_memberships(body)
    stub_request(:get, memberships_url)
      .to_return(status: 200, body: body.to_json,
                 headers: { 'Content-Type' => 'application/json' })
  end

  it 'creates an LtiContext for each member and updates last_roster_sync_at' do
    stub_memberships(
      'members' => [
        { 'userId' => 'lti-1', 'name' => 'Alice', 'email' => 'alice@example.edu',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
          'status' => 'Active' },
        { 'userId' => 'lti-2', 'name' => 'Bob', 'email' => 'bob@example.edu',
          'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'],
          'status' => 'Active' }
      ]
    )

    expect { described_class.new(binding) }
      .to change(LtiContext, :count).by(2)
    expect(binding.reload.last_roster_sync_at).to be_present
  end

  it 'is a no-op when the binding has no stored serviceKey' do
    binding.update!(ltiaas_service_credentials: nil)
    expect { described_class.new(binding) }
      .not_to change(LtiContext, :count)
    expect(binding.reload.last_roster_sync_at).to be_nil
    expect(WebMock).not_to have_requested(:get, memberships_url)
  end

  it 'continues past per-member errors and reports them to Sentry' do
    stub_memberships(
      'members' => [
        { 'userId' => 'lti-good', 'email' => 'good@example.edu',
          'roles' => ['#Learner'], 'status' => 'Active' },
        { 'userId' => 'lti-bad', 'email' => 'bad@example.edu',
          'roles' => ['#Learner'], 'status' => 'Active' }
      ]
    )
    allow(LtiMemberLinker).to receive(:new).and_call_original
    allow(LtiMemberLinker).to receive(:new)
      .with(anything, hash_including(user_lti_id: 'lti-bad'))
      .and_raise(StandardError, 'boom')
    expect(Sentry).to receive(:capture_exception)

    described_class.new(binding)
    expect(LtiContext.where(user_lti_id: 'lti-good')).to exist
  end
end
