# frozen_string_literal: true

require 'rails_helper'

describe BuildLtiDeepLinkForm do
  let(:domain) { 'tenant.ltiaas.com' }
  let(:ltik) { 'launch-token' }
  let(:form_url) { "https://#{domain}/api/deeplinking/form" }
  let(:form_html) { '<form id="ltiaas-dl"></form><script>document.forms[0].submit()</script>' }
  let(:gradable) do
    DeepLinkableGradables::Gradable.new(resource: 'Block:42', gradable_type: 'Block',
                                        gradable_id: 42, label: 'Wk1 Find sources',
                                        description: '<p>Find three reliable sources.</p>')
  end

  before do
    ENV['LTIAAS_DOMAIN'] = domain
    ENV['LTIAAS_API_KEY'] = 'api-key'
  end

  subject(:service) { described_class.new(ltik:, gradables: [gradable]) }

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
               item['lineItem']['label'] == 'Wk1 Find sources' &&
               # Canvas turns content-item `text` into the assignment
               # description — sourced from the Dashboard block body.
               item['text'] == '<p>Find three reliable sources.</p>'
           end
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    service
    expect(stub).to have_been_requested
  end

  it 'posts one content item per gradable, in the given order (bulk mode)' do
    second = DeepLinkableGradables::Gradable.new(
      resource: 'TrainingProgress', gradable_type: 'TrainingProgress',
      gradable_id: nil, label: 'Wikipedia trainings',
      description: '<ul><li>Wikipedia essentials</li></ul>'
    )
    stub = stub_request(:post, form_url)
           .with do |request|
             items = JSON.parse(request.body)['contentItems']
             items.length == 2 &&
               items.map { |i| i['title'] } == ['Wikipedia trainings', 'Wk1 Find sources'] &&
               items.all? { |i| i['lineItem'].present? && i['text'].present? }
           end
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    described_class.new(ltik:, gradables: [second, gradable])
    expect(stub).to have_been_requested
  end

  it 'asks Canvas to name the created module via the module_name claim' do
    stub = stub_request(:post, form_url)
           .with(body: hash_including(
             'https://canvas.instructure.com/lti/module_name' =>
               'Research and write a Wikipedia article'
           ))
           .to_return(status: 200, body: { 'form' => form_html }.to_json,
                      headers: { 'Content-Type' => 'application/json' })
    service
    expect(stub).to have_been_requested
  end

  it 'retries without the module_name claim if LTIAAS rejects it' do
    stub_request(:post, form_url)
      .with(body: hash_including('https://canvas.instructure.com/lti/module_name'))
      .to_return(status: 400, body: { error: 'unknown field' }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    fallback = stub_request(:post, form_url)
               .with { |req| !JSON.parse(req.body).key?('https://canvas.instructure.com/lti/module_name') }
               .to_return(status: 200, body: { 'form' => form_html }.to_json,
                          headers: { 'Content-Type' => 'application/json' })
    expect(service.form).to eq(form_html)
    expect(fallback).to have_been_requested
  end
end
