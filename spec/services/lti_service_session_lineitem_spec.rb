# frozen_string_literal: true

require 'rails_helper'

describe 'LtiServiceSession AGS line-item verbs', type: :service do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:binding) do
    LtiCourseBinding.create!(
      lms_id: 'p', lms_family: 'canvas',
      lms_context_id: 'c', lms_resource_link_id: 'rl-99',
      ltiaas_service_credentials: 'svc-key'
    )
  end

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { LtiServiceSession.new(binding) }

  describe '#upsert_line_item (POST /api/lineitems)' do
    it 'sends required fields and returns the created lineitem id' do
      stub = stub_request(:post, "https://#{domain}/api/lineitems")
             .with(headers: { 'Authorization' => 'SERVICE-AUTH-V1 api-key:svc-key' },
                   body: hash_including(label: 'Activity 1', scoreMaximum: 1.0,
                                        tag: 'Block:42', resourceLinkId: 'rl-99'))
             .to_return(status: 201,
                        body: { id: 'https://lms.example.com/li/abc', label: 'Activity 1',
                                scoreMaximum: 1.0 }.to_json,
                        headers: { 'Content-Type' => 'application/json' })

      lineitem_id = service.upsert_line_item(label: 'Activity 1', tag: 'Block:42',
                                             resource_link_id: 'rl-99')
      expect(lineitem_id).to eq('https://lms.example.com/li/abc')
      expect(stub).to have_been_requested
    end

    it 'omits optional fields when not provided' do
      stub = stub_request(:post, "https://#{domain}/api/lineitems")
             .with(body: { label: 'Plain', scoreMaximum: 1.0 })
             .to_return(status: 201, body: { id: 'http://x/1' }.to_json,
                        headers: { 'Content-Type' => 'application/json' })
      service.upsert_line_item(label: 'Plain')
      expect(stub).to have_been_requested
    end
  end



  describe '#list_line_items (GET /api/lineitems, paginated)' do
    it 'follows the next field to aggregate all pages' do
      page_one = {
        lineItems: [{ id: 'http://x/1', label: 'A', scoreMaximum: 1.0 }],
        next: 'https://lms.example.com/lineitems?page=2'
      }
      page_two = {
        lineItems: [{ id: 'http://x/2', label: 'B', scoreMaximum: 1.0 }]
      }
      stub_request(:get, "https://#{domain}/api/lineitems")
        .to_return(status: 200, body: page_one.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      stub_request(:get,
                   "https://#{domain}/api/lineitems?url=" \
                   "#{CGI.escape('https://lms.example.com/lineitems?page=2')}")
        .to_return(status: 200, body: page_two.to_json,
                   headers: { 'Content-Type' => 'application/json' })

      items = service.list_line_items
      expect(items.size).to eq(2)
      expect(items.map { |i| i['id'] }).to eq(['http://x/1', 'http://x/2'])
    end

    it 'passes resource_link_id and tag filters as query params' do
      stub = stub_request(:get,
                          "https://#{domain}/api/lineitems?" \
                          'resourceLinkId=rl-99&tag=Block%3A42')
             .to_return(status: 200, body: { lineItems: [] }.to_json,
                        headers: { 'Content-Type' => 'application/json' })
      service.list_line_items(resource_link_id: 'rl-99', tag: 'Block:42')
      expect(stub).to have_been_requested
    end
  end
end
