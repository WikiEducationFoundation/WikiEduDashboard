# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe ArticleAuditing::Checks::CitationSupport do
  let(:check) { described_class.new('model' => 'claude-opus-5-5', 'effort' => 'low') }
  let(:sup) { ->(n) { %(<sup class="reference"><a href="#cite_note-#{n}">[#{n}]</a></sup>) } }
  let(:html) do
    <<~HTML
      <p>The library opened downtown.#{sup[1]} It had a million books.#{sup[1]}</p>
      <p>Its founder was a printer.#{sup[2]} It closed later.#{sup[3]}</p>
      <ol class="references">
        <li id="cite_note-1"><span class="reference-text"><cite>"History". <a class="external" href="https://example.com/history">Example</a></cite></span></li>
        <li id="cite_note-2"><span class="reference-text"><cite>Smith, J. <i>A Book</i>. 1950.</cite></span></li>
        <li id="cite_note-3"><span class="reference-text"><cite><a class="external" href="https://example.com/gone">Gone</a></cite></span></li>
      </ol>
    HTML
  end
  let(:context) do
    instance_double(ArticleAuditing::Context,
                    html:, wikitext: '',
                    plaintext: 'The library opened downtown. It had a million books. ' \
                               'Its founder was a printer. It closed later.')
  end
  let(:adapter) { instance_double(Llm::AnthropicAdapter) }
  let(:verdicts) do
    [{ 'claim' => 1, 'verdict' => 'supported', 'quote' => 'opened downtown',
       'explanation' => 'Matches.' },
     { 'claim' => 2, 'verdict' => 'not_supported', 'quote' => '',
       'explanation' => 'The page gives no collection size.' },
     { 'claim' => 99, 'verdict' => 'contradicted', 'quote' => '', 'explanation' => 'Made up.' }]
  end
  let(:filler) { 'The reading room seated two hundred people at long oak tables. ' * 4 }
  let(:output) { check.run(context) }
  let(:rows) { output.artifacts[:claims] }

  before do
    allow(Resolv).to receive(:getaddresses).and_return(['93.184.215.14'])
    stub_const('ClaimVerification::HostThrottle::INTERVAL', 0)
    stub_request(:get, 'https://example.com/history')
      .to_return(status: 200, body: "<p>The library opened downtown.</p><p>#{filler}</p>",
                 headers: { 'Content-Type' => 'text/html' })
    stub_request(:get, 'https://example.com/gone').to_return(status: 404)
    allow(Llm::Client).to receive(:adapter).with('anthropic').and_return(adapter)
    allow(adapter).to receive(:complete).and_return(
      Llm::Response.new(text: '{}', json: { 'verdicts' => verdicts }, model: 'claude-opus-5-5',
                        usage: { 'input_tokens' => 300, 'output_tokens' => 40 })
    )
  end

  it 'judges each fetched source once, with the source as system text and its claims' do
    output
    expect(adapter).to have_received(:complete).once.with(
      system_blocks: [{ text: check.prompt, cache: false },
                      { text: a_string_including('<citation>"History". Example</citation>',
                                                 'The library opened downtown.'),
                        cache: false }],
      user: a_string_including('<claim id="1">', '<claim id="2">'),
      json_schema: ArticleAuditing::CitationJudge::SCHEMA, model: 'claude-opus-5-5', effort: 'low'
    )
  end

  it 'lists a row per sentence and source, including sources it could not read' do
    expect(rows.pluck('verdict')).to eq(%w[supported not_supported source_offline
                                           source_inaccessible])
    expect(rows.first).to include('url' => 'https://example.com/history',
                                  'evidence' => 'opened downtown')
  end

  it 'reports sentences their sources do not support, ignoring made-up claim ids' do
    expect(output.findings.size).to eq(1)
    expect(output.findings.first).to include(
      'severity' => 'should_fix', 'explanation' => 'The page gives no collection size.',
      'title' => I18n.t('article_audit.citation_verdicts.not_supported')
    )
    expect(output.findings.first['location']).to include('quote' => 'It had a million books.',
                                                         'quote_verified' => true)
  end

  it 'records usage and counts' do
    expect(output.usage).to include('input_tokens' => 300, 'claims' => 4, 'sources' => 3,
                                    'sources_fetched' => 1, 'model' => 'claude-opus-5-5')
  end

  context 'with more cited sentences than max_claims' do
    let(:check) { described_class.new('model' => 'claude-opus-5-5', 'max_claims' => 2) }

    it 'checks only the first ones, and counts the rest' do
      expect(rows.pluck('claim')).to eq(['The library opened downtown.', 'It had a million books.'])
      expect(output.usage).to include('claims' => 2, 'claims_over_cap' => 2, 'sources' => 1)
      expect(WebMock).not_to have_requested(:get, 'https://example.com/gone')
    end
  end

  it 'does not use the shared article cache' do
    expect(check.shares_article_cache?).to be(false)
  end

  it 'fails when every judgment fails' do
    allow(adapter).to receive(:complete).and_raise(Llm::RetryableError, 'overloaded')
    expect { output }.to raise_error(Llm::RetryableError)
  end

  context 'with a sentence that cites a supporting and a non-supporting source' do
    let(:html) do
      <<~HTML
        <p>The library opened downtown.#{sup[1]}#{sup[3]}</p>
        <ol class="references">
          <li id="cite_note-1"><span class="reference-text"><a class="external" href="https://example.com/history">A</a></span></li>
          <li id="cite_note-3"><span class="reference-text"><a class="external" href="https://example.com/other">B</a></span></li>
        </ol>
      HTML
    end

    before do
      stub_request(:get, 'https://example.com/other')
        .to_return(status: 200, body: "<p>Unrelated.</p><p>#{filler}</p>",
                   headers: { 'Content-Type' => 'text/html' })
      allow(adapter).to receive(:complete) do |system_blocks:, **|
        verdict = system_blocks.last[:text].include?('opened') ? 'supported' : 'not_supported'
        Llm::Response.new(text: '{}', model: 'm', usage: {},
                          json: { 'verdicts' => [{ 'claim' => 1, 'verdict' => verdict,
                                                   'quote' => '', 'explanation' => '' }] })
      end
    end

    it 'counts the sentence as supported' do
      expect(output.findings).to be_empty
      expect(rows.pluck('verdict')).to contain_exactly('supported', 'not_supported')
    end
  end
end

describe ArticleAuditing::CitationJudge do
  let(:adapter) { instance_double(Llm::AnthropicAdapter) }
  let(:judge) { described_class.new(adapter:, prompt: 'p', model: 'm', effort: 'low') }
  let(:source) do
    ClaimVerification::FetchedSource.new(status: :fetched, text: 'x' * 10, url: 'https://e.x/',
                                         reason: nil)
  end
  let(:claims) do
    (1..25).to_h { |id| [id, ClaimVerification::Claim.new(sentence: "S#{id}.", ref_ids: [], context: "S#{id}.")] }
  end

  before do
    allow(adapter).to receive(:complete) do |user:, **|
      ids = user.scan(/claim id="(\d+)"/).flatten.map(&:to_i)
      verdicts = ids.map do |id|
        { 'claim' => id, 'verdict' => 'supported', 'quote' => '', 'explanation' => '' }
      end
      Llm::Response.new(text: '{}', model: 'm', usage: { 'input_tokens' => 1 },
                        json: { 'verdicts' => verdicts })
    end
  end

  it 'splits many claims into batches that share a cached source block' do
    judgment = judge.judge(claims, source, 'A citation')
    expect(adapter).to have_received(:complete).twice
    expect(adapter).to have_received(:complete)
      .with(hash_including(system_blocks: [{ text: 'p', cache: false },
                                           { text: a_string_including('xxxx'), cache: true }]))
      .twice
    expect(judgment.verdicts.keys).to eq((1..25).to_a)
    expect(judgment.usage).to eq('input_tokens' => 2)
  end
end
