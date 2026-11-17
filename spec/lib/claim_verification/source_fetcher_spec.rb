# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/source_fetcher"
require "#{Rails.root}/lib/claim_verification/citation"

describe ClaimVerification::SourceFetcher do
  def citation(urls: [], archive_urls: [])
    ClaimVerification::Citation.new(ref_id: 'cite_note-1', cite_html: '',
                                    cite_text: 'A source.', urls:, archive_urls:)
  end

  # Every host resolves to a public address unless a spec says otherwise.
  before do
    allow(Resolv).to receive(:getaddresses).and_return(['93.184.215.14'])
    stub_const('ClaimVerification::HostThrottle::INTERVAL', 0)
  end

  let(:page_html) do
    <<~HTML
      <html><head><title>Page</title><script>tracking();</script></head>
      <body>
        <nav>Home | About</nav>
        <article><p>The library opened in 1923.</p>
        <p>It moved buildings in 1958.</p>
        <p>#{'The reading room seated two hundred people at long oak tables. ' * 4}</p></article>
        <footer>Copyright</footer>
      </body></html>
    HTML
  end

  context 'when the source URL responds with HTML' do
    before do
      stub_request(:get, 'https://example.com/history')
        .to_return(status: 200, body: page_html,
                   headers: { 'Content-Type' => 'text/html; charset=utf-8' })
    end

    let(:result) { described_class.new(citation(urls: ['https://example.com/history'])).result }

    it 'returns fetched readable text' do
      expect(result.fetched?).to eq(true)
      expect(result.text).to include('The library opened in 1923.')
      expect(result.url).to eq('https://example.com/history')
    end

    it 'strips scripts and navigation chrome' do
      expect(result.text).not_to include('tracking();')
      expect(result.text).not_to include('Home | About')
    end
  end

  context 'when the citation has no URLs' do
    it 'classifies the source as offline' do
      result = described_class.new(citation).result
      expect(result.status).to eq(:offline_source)
      expect(result.text).to be_nil
    end
  end

  context 'when the primary URL fails but an archive URL works' do
    before do
      stub_request(:get, 'https://example.com/dead').to_return(status: 404)
      stub_request(:get, 'https://web.archive.org/web/2024/https://example.com/dead')
        .to_return(status: 200, body: page_html,
                   headers: { 'Content-Type' => 'text/html' })
    end

    it 'falls back to the archive' do
      result = described_class.new(
        citation(urls: ['https://example.com/dead'],
                 archive_urls: ['https://web.archive.org/web/2024/https://example.com/dead'])
      ).result
      expect(result.fetched?).to eq(true)
      expect(result.url).to include('web.archive.org')
    end
  end

  context 'when all URLs are inaccessible' do
    before do
      stub_request(:get, 'https://example.com/paywalled').to_return(status: 403)
    end

    it 'classifies the source as inaccessible with the reason' do
      result = described_class.new(citation(urls: ['https://example.com/paywalled'])).result
      expect(result.status).to eq(:inaccessible)
      expect(result.reason).to include('HTTP 403')
    end
  end

  context 'when the URL serves a PDF' do
    before do
      stub_request(:get, 'https://example.com/paper.pdf')
        .to_return(status: 200, body: '%PDF-1.5',
                   headers: { 'Content-Type' => 'application/pdf' })
    end

    it 'classifies the source as inaccessible' do
      result = described_class.new(citation(urls: ['https://example.com/paper.pdf'])).result
      expect(result.status).to eq(:inaccessible)
      expect(result.reason).to include('application/pdf')
    end
  end

  context 'when the request times out' do
    before do
      stub_request(:get, 'https://example.com/slow').to_timeout
    end

    it 'classifies the source as inaccessible' do
      result = described_class.new(citation(urls: ['https://example.com/slow'])).result
      expect(result.status).to eq(:inaccessible)
    end
  end

  context 'when the URL redirects' do
    before do
      stub_request(:get, 'https://example.com/old')
        .to_return(status: 301, headers: { 'Location' => 'https://example.com/new' })
      stub_request(:get, 'https://example.com/new')
        .to_return(status: 200, body: page_html, headers: { 'Content-Type' => 'text/html' })
    end

    it 'follows the redirect' do
      result = described_class.new(citation(urls: ['https://example.com/old'])).result
      expect(result.fetched?).to eq(true)
    end
  end

  context 'when a redirect has no Location header' do
    before do
      stub_request(:get, 'https://example.com/nowhere').to_return(status: 302)
    end

    it 'classifies the source as inaccessible' do
      result = described_class.new(citation(urls: ['https://example.com/nowhere'])).result
      expect(result.status).to eq(:inaccessible)
      expect(result.reason).to include('HTTP 302')
    end
  end

  context 'when redirects loop' do
    before do
      stub_request(:get, 'https://example.com/loop')
        .to_return(status: 302, headers: { 'Location' => 'https://example.com/loop' })
    end

    it 'gives up and classifies the source as inaccessible' do
      result = described_class.new(citation(urls: ['https://example.com/loop'])).result
      expect(result.status).to eq(:inaccessible)
      expect(result.reason).to include('TooManyRedirectsError')
    end
  end

  context 'when a host resolves to an internal address' do
    before do
      allow(Resolv).to receive(:getaddresses).with('intranet.example').and_return(['10.0.0.5'])
    end

    it 'refuses to fetch it' do
      result = described_class.new(citation(urls: ['http://intranet.example/admin'])).result
      expect(result.status).to eq(:inaccessible)
      expect(result.reason).to include('DisallowedUrlError')
    end
  end

  context 'when a public URL redirects to an internal address' do
    before do
      allow(Resolv).to receive(:getaddresses).with('127.0.0.1').and_return(['127.0.0.1'])
      stub_request(:get, 'https://example.com/sneaky')
        .to_return(status: 302, headers: { 'Location' => 'http://127.0.0.1/secret' })
    end

    it 'refuses to follow the redirect' do
      result = described_class.new(citation(urls: ['https://example.com/sneaky'])).result
      expect(result.reason).to include('DisallowedUrlError')
      expect(a_request(:get, 'http://127.0.0.1/secret')).not_to have_been_made
    end
  end

  context 'when the page has almost no readable text' do
    before do
      stub_request(:get, 'https://example.com/app')
        .to_return(status: 200, body: '<html><body><div id="root"></div>Loading…</body></html>',
                   headers: { 'Content-Type' => 'text/html' })
    end

    it 'classifies the source as inaccessible' do
      result = described_class.new(citation(urls: ['https://example.com/app'])).result
      expect(result.reason).to include('no readable text')
    end
  end

  context 'when the URL is not http(s)' do
    it 'refuses to fetch it' do
      result = described_class.new(citation(urls: ['ftp://example.com/file'])).result
      expect(result.reason).to include('DisallowedUrlError')
    end
  end
end
