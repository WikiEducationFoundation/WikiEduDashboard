# frozen_string_literal: true

require 'rails_helper'

describe LtiServiceSession do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'platform-x',
      lms_family: 'canvas',
      lms_context_id: 'canvas-course-77',
      lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key'
    )
  end

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { described_class.new(binding) }

  describe '#fetch_memberships' do
    let(:memberships_url) { "https://#{domain}/api/memberships" }

    def stub_memberships_page(url, body)
      stub_request(:get, url)
        .with(headers: {
                'Authorization' => 'SERVICE-AUTH-V1 api-key:svc-key'
              })
        .to_return(status: 200, body: body.to_json,
                   headers: { 'Content-Type' => 'application/json' })
    end

    let(:page_one) do
      {
        'members' => [
          { 'userId' => 'lti-1', 'name' => 'Alice', 'email' => 'alice@example.edu',
            'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Instructor'],
            'status' => 'Active' }
        ],
        'next' => 'https://lms.example.com/memberships?page=2'
      }
    end

    let(:page_two) do
      {
        'members' => [
          { 'userId' => 'lti-2', 'name' => 'Bob', 'email' => 'bob@example.edu',
            'roles' => ['http://purl.imsglobal.org/vocab/lis/v2/membership#Learner'],
            'status' => 'Active' }
        ]
      }
    end

    it 'follows pagination via the response next field' do
      stub_memberships_page(memberships_url, page_one)
      stub_memberships_page(
        "#{memberships_url}?url=#{CGI.escape('https://lms.example.com/memberships?page=2')}",
        page_two
      )

      members = service.fetch_memberships
      expect(members.size).to eq(2)
      expect(members.first[:user_lti_id]).to eq('lti-1')
      expect(members.first[:email]).to eq('alice@example.edu')
      expect(members.first[:status]).to eq('Active')
      expect(members.last[:user_lti_id]).to eq('lti-2')
    end

    it 'passes a role filter when provided' do
      stub_memberships_page("#{memberships_url}?role=Learner", page_two)

      members = service.fetch_memberships(role: 'Learner')
      expect(members.size).to eq(1)
      expect(members.first[:user_lti_id]).to eq('lti-2')
    end
  end

  describe 'binding accessor' do
    it 'exposes the binding it was constructed with' do
      expect(service.binding).to eq(binding)
    end
  end
end
