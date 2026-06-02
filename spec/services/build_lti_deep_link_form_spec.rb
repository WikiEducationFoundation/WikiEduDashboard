# frozen_string_literal: true

require 'rails_helper'

describe BuildLtiDeepLinkForm do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:ltik) { 'launch-token' }
  let(:form_url) { "https://#{domain}/api/deeplinking/form" }
  let(:form_html) { '<form id="ltiaas-dl"></form><script>document.forms[0].submit()</script>' }
  let(:gradable) do
    DeepLinkableGradables::Gradable.new(resource: 'Block:42', gradable_type: 'Block',
                                        gradable_id: 42, label: 'Wk1 Find sources')
  end

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { described_class.new(ltik:, gradable:) }

  it 'requests the self-submitting form from LTIAAS with LTIK auth' do
    stub = stub_request(:post, form_url)
           .with(headers: { 'Authorization' => "LTIK-AUTH-V2 api-key:#{ltik}" })
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    service
    expect(stub).to have_been_requested
  end

  it 'returns the form HTML returned by LTIAAS' do
    stub_request(:post, form_url)
      .to_return(status: 200, body: { 'form' => form_html }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    expect(service.form).to eq(form_html)
  end

  it 'posts one ltiResourceLink content item keyed to the chosen gradable' do
    stub = stub_request(:post, form_url)
           .with do |request|
             items = JSON.parse(request.body)['contentItems']
             item = items.first
             items.length == 1 &&
               item['type'] == 'ltiResourceLink' &&
               item['custom'] == { 'resource' => 'Block:42' } &&
               item['url'].include?('resource=Block%3A42') &&
               item['lineItem']['label'] == 'Wk1 Find sources'
           end
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    service
    expect(stub).to have_been_requested
  end
end
