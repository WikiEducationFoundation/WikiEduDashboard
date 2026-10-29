# frozen_string_literal: true

require 'rails_helper'
require 'tmpdir'
require "#{Rails.root}/lib/claim_library/source_fetcher"

describe ClaimLibrary::SourceFetcher do
  around do |example|
    Dir.mktmpdir { |dir| @cache_dir = dir; example.run }
  end

  let(:fetcher) { described_class.new(cache_dir: @cache_dir, contact: 'dev@example.org') }
  let(:page) { '<html><body><p>The committee critically engaged with the Bill.</p></body></html>' }
  let(:live_url) { 'https://example.org/report' }

  it 'reads a live page and says where it read it from' do
    stub_request(:get, live_url).to_return(status: 200, body: page,
                                           headers: { 'Content-Type' => 'text/html' })
    source = fetcher.fetch(live_url)
    expect(source).to be_readable
    expect(source.read_from).to eq(live_url)
    expect(source.text).to eq('The committee critically engaged with the Bill.')
  end

  it 'follows a redirect' do
    stub_request(:get, live_url)
      .to_return(status: 301, headers: { 'Location' => 'https://example.org/moved' })
    stub_request(:get, 'https://example.org/moved')
      .to_return(status: 200, body: page, headers: { 'Content-Type' => 'text/html' })
    expect(fetcher.fetch(live_url).read_from).to eq('https://example.org/moved')
  end

  it 'prefers the full text service for an article with a PMC id' do
    pmc = 'https://pmc.ncbi.nlm.nih.gov/articles/PMC10327345/'
    stub_request(:get, 'https://www.ebi.ac.uk/europepmc/webservices/rest/PMC10327345/fullTextXML')
      .to_return(status: 200, body: '<article><body><p>Full text.</p></body></article>',
                 headers: { 'Content-Type' => 'application/xml' })
    source = fetcher.fetch(pmc)
    expect(source.text).to eq('Full text.')
    expect(a_request(:get, pmc)).not_to have_been_made
  end

  it 'falls back to the archive snapshot nearest the revision when the live page is gone' do
    stub_request(:get, live_url).to_return(status: 404)
    stub_request(:get, 'https://archive.org/wayback/available?url=https%3A%2F%2Fexample.org%2Freport&timestamp=20251113')
      .to_return(status: 200, body: { archived_snapshots: { closest: {
        url: 'https://web.archive.org/web/20240503035659/https://example.org/report'
      } } }.to_json)
    stub_request(:get, 'https://web.archive.org/web/20240503035659id_/https://example.org/report')
      .to_return(status: 200, body: page, headers: { 'Content-Type' => 'text/html' })

    source = fetcher.fetch(live_url, timestamp: Time.zone.parse('2025-11-13'))
    expect(source).to be_readable
    expect(source.read_from).to include('20240503035659id_')
  end

  it 'uses the archive link the citation carries before asking the Wayback Machine' do
    stub_request(:get, live_url).to_return(status: 403)
    stub_request(:get, 'https://web.archive.org/web/2024id_/https://example.org/report')
      .to_return(status: 200, body: page, headers: { 'Content-Type' => 'text/html' })
    source = fetcher.fetch(live_url, archive_url: 'https://web.archive.org/web/2024/https://example.org/report')
    expect(source.read_from).to eq('https://web.archive.org/web/2024id_/https://example.org/report')
  end

  it 'reports every copy it tried when none could be read' do
    stub_request(:get, live_url).to_return(status: 403)
    stub_request(:get, %r{archive\.org/wayback/available}).to_return(status: 200, body: '{}')
    source = fetcher.fetch(live_url)
    expect(source).not_to be_readable
    expect(source.error).to include("#{live_url}: HTTP 403")
    expect(Dir.children(@cache_dir)).to be_empty
  end

  it 'reads a source once and serves it from the cache after that' do
    stub = stub_request(:get, live_url).to_return(status: 200, body: page,
                                                  headers: { 'Content-Type' => 'text/html' })
    first = fetcher.fetch(live_url)
    second = described_class.new(cache_dir: @cache_dir, contact: 'dev@example.org').fetch(live_url)
    expect(stub).to have_been_requested.once
    expect(second.text).to eq(first.text)
    expect(second.read_from).to eq(live_url)
  end
end
