# frozen_string_literal: true

require 'rails_helper'

describe BuildLtiDeepLinkForm do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:ltik) { 'launch-token' }
  let(:form_url) { "https://#{domain}/api/deeplinking/form" }
  let(:form_html) { '<form id="ltiaas-dl"></form><script>document.forms[0].submit()</script>' }

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { described_class.new(ltik:) }

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

  it 'posts a single ltiResourceLink content item carrying a lineItem' do
    stub = stub_request(:post, form_url)
           .with do |request|
             items = JSON.parse(request.body)['contentItems']
             items.length == 1 &&
               items.first['type'] == 'ltiResourceLink' &&
               items.first['lineItem'].present?
           end
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    service
    expect(stub).to have_been_requested
  end
end
