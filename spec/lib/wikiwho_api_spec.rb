# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wikiwho_api"

describe WikiWhoApi do
  let(:wiki) { Wiki.default_wiki }
  let(:url) { %r{wikiwho-api.wmcloud.org/en/api/v1.0.0-beta/rev_content/rev_id/123/} }
  let(:tokens) { [{ 'str' => 'aksum', 'o_rev_id' => 100, 'editor' => '42' }] }

  it 'returns the tokens of a revision' do
    body = { success: true, revisions: [{ '123' => { tokens: } }] }.to_json
    stub_request(:get, url).to_return(status: 200, body:)
    expect(described_class.new(wiki).rev_content(123)).to eq(tokens)
  end

  it 'returns nil when WikiWho reports a failure' do
    stub_request(:get, url).to_return(status: 200, body: { success: false }.to_json)
    expect(described_class.new(wiki).rev_content(123)).to be_nil
  end

  it 'returns nil for an error status' do
    stub_request(:get, url).to_return(status: 400, body: '{}')
    expect(described_class.new(wiki).rev_content(123)).to be_nil
  end

  it 'returns nil when the request fails' do
    stub_request(:get, url).to_timeout
    expect(described_class.new(wiki).rev_content(123)).to be_nil
  end
end
