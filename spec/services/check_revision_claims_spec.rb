# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/llm/client"

describe CheckRevisionClaims do
  let(:revision_html) do
    <<~HTML
      <p>The library opened in 1923.<sup class="reference">
        <a href="#cite_note-lib-1">[1]</a></sup>
      It moved buildings in 1958.<sup class="reference">
        <a href="#cite_note-lib-1">[1]</a></sup>
      The mayor cut the ribbon.<sup class="reference">
        <a href="#cite_note-paper-2">[2]</a></sup></p>
      <ol class="references">
        <li id="cite_note-lib-1"><span class="reference-text">
          <cite class="citation web cs1">
            <a class="external text" href="https://example.com/library">"Library history"</a>
          </cite></span></li>
        <li id="cite_note-paper-2"><span class="reference-text">
          <cite class="citation book cs1">Smith, J. (1990). <i>Town History</i>.</cite>
        </span></li>
      </ol>
    HTML
  end

  let(:judge_json) do
    { 'verdict' => 'supported', 'quote' => 'opened in 1923', 'explanation' => 'stated directly' }
  end

  before do
    allow_any_instance_of(WikiApi::ArticleContent)
      .to receive(:revision_html)
      .and_return({ html: revision_html, title: 'Library', page_id: 1 })

    stub_request(:get, 'https://example.com/library')
      .to_return(status: 200,
                 body: '<html><body>The library opened in 1923 and moved in 1958.</body></html>',
                 headers: { 'Content-Type' => 'text/html' })

    adapter = instance_double(Llm::AnthropicAdapter)
    allow(Llm::Client).to receive(:adapter).and_return(adapter)
    allow(adapter).to receive(:complete)
      .and_return(Llm::Response.new(text: judge_json.to_json, json: judge_json,
                                    model: 'claude-opus-4-8',
                                    usage: { input_tokens: 10, output_tokens: 5 }))
  end

  context 'with a single-revision URL' do
    let(:url) { 'https://en.wikipedia.org/w/index.php?title=Library&oldid=12345' }
    let(:check) { described_class.new(url, extract_mode: :structural) }

    it 'produces one result per claim-citation pair' do
      expect(check.results.length).to eq(3)
    end

    it 'judges claims whose source was fetched' do
      fetched = check.results.select { |r| r[:source].fetched? }
      expect(fetched.length).to eq(2)
      expect(fetched.map { |r| r[:verdict].verdict }.uniq).to eq(['supported'])
    end

    it 'marks claims with offline sources as source_inaccessible without judging' do
      offline = check.results.find { |r| !r[:source].fetched? }
      expect(offline[:source].status).to eq(:offline_source)
      expect(offline[:verdict].verdict).to eq('source_inaccessible')
    end

    it 'fetches each distinct source only once' do
      check
      expect(WebMock).to have_requested(:get, 'https://example.com/library').once
    end

    it 'exposes the article title' do
      expect(check.article_title).to eq('Library')
    end
  end

  context 'with a diff URL' do
    let(:url) do
      'https://en.wikipedia.org/w/index.php?title=Library&diff=12345&oldid=12000'
    end

    it 'requests the diff between the two revisions' do
      expect(GetRevisionHtmlWithCitations)
        .to receive(:new).with(12_345, anything, diff_mode: true, from_rev: 12_000)
        .and_return(instance_double(GetRevisionHtmlWithCitations,
                                    html: nil, article_title: nil))
      described_class.new(url)
    end
  end

  context 'with a prev-diff URL' do
    let(:url) { 'https://en.wikipedia.org/w/index.php?title=Library&diff=prev&oldid=12345' }

    it 'lets the parent revision be fetched automatically' do
      expect(GetRevisionHtmlWithCitations)
        .to receive(:new).with(12_345, anything, diff_mode: true, from_rev: nil)
        .and_return(instance_double(GetRevisionHtmlWithCitations,
                                    html: nil, article_title: nil))
      described_class.new(url)
    end
  end

  context 'when the revision HTML is unavailable' do
    let(:url) { 'https://en.wikipedia.org/w/index.php?title=Library&oldid=12345' }

    it 'returns empty results' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_html).and_return({ html: nil, title: nil, page_id: nil })
      expect(described_class.new(url).results).to be_empty
    end
  end
end
