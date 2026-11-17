# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe ArticleAuditing::LlmCheck do
  let(:check) { ArticleAuditing::Checks::Tone.new('model' => 'claude-opus-5-5', 'effort' => 'low') }
  let(:system_blocks) { [{ text: 'system', cache: false }, { text: 'article', cache: true }] }
  let(:context) do
    instance_double(ArticleAuditing::Context,
                    llm_system_blocks: system_blocks,
                    wikitext: "'''Acme''' is a [[world-class]] company.<ref>x</ref>",
                    plaintext: 'Acme is a world-class company.')
  end
  let(:adapter) { instance_double(Llm::AnthropicAdapter) }
  let(:llm_findings) do
    [
      { 'severity' => 'should_fix', 'title' => 'Peacock term', 'explanation' => 'Puffery.',
        'section' => 'Lead', 'quote' => 'is a world-class   company', 'suggestion' => '',
        'policy_refs' => ['WP:PEACOCK'] },
      { 'severity' => 'urgent', 'title' => 'Invented', 'explanation' => 'x', 'section' => '',
        'quote' => 'text that is not in the article', 'suggestion' => 'y', 'policy_refs' => [] }
    ]
  end
  let(:llm_response) do
    Llm::Response.new(text: '{}', json: { 'findings' => llm_findings }, model: 'claude-opus-5-5',
                      usage: { 'input_tokens' => 10, 'output_tokens' => 5 })
  end

  before do
    allow(Llm::Client).to receive(:adapter).with('anthropic').and_return(adapter)
    allow(adapter).to receive(:complete).and_return(llm_response)
  end

  it 'sends the shared system blocks, its own prompt, schema, model and effort' do
    check.run(context)
    expect(adapter).to have_received(:complete).with(
      system_blocks:, user: check.prompt, json_schema: check.schema,
      model: 'claude-opus-5-5', effort: 'low'
    )
    expect(check.prompt).to include('tone')
  end

  it 'maps findings into the shared shape' do
    findings = check.run(context).findings
    expect(findings.first).to include('check' => 'tone', 'category' => 'tone',
                                      'severity' => 'should_fix', 'suggestion' => nil)
    expect(findings.first['location']).to include('section' => 'Lead')
  end

  it 'replaces an unknown severity' do
    expect(check.run(context).findings.last['severity']).to eq('suggestion')
  end

  it 'marks quotes that do not appear in the article and counts them' do
    output = check.run(context)
    expect(output.findings.map { |f| f.dig('location', 'quote_verified') }).to eq([true, false])
    expect(output.usage).to include('unverified_quotes' => 1, 'input_tokens' => 10,
                                    'model' => 'claude-opus-5-5')
  end

  it 'reports its engine and a version that tracks the prompt' do
    expect(check.engine).to eq('anthropic:claude-opus-5-5')
    original_version = check.version
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with(described_class::PROMPT_DIR.join('tone.md'))
                                 .and_return('a different prompt')
    expect(ArticleAuditing::Checks::Tone.new.version).not_to eq(original_version)
  end

  it 'has a version that also tracks the shared system prompt' do
    original_version = check.version
    allow(described_class).to receive(:system_prompt).and_return('different instructions')
    expect(ArticleAuditing::Checks::Tone.new.version).not_to eq(original_version)
  end

  it 'has a prompt file for every LLM check in the registry' do
    ArticleAuditing::Registry.keys.map { |key| ArticleAuditing::Registry.check(key) }
                             .grep(described_class).each do |llm_check|
      expect(llm_check.prompt).to be_present
    end
  end

  describe 'checks with artifacts' do
    it 'shares one schema, with every artifact as an optional field' do
      schema = ArticleAuditing::Checks::SourceTable.new.schema
      expect(schema).to eq(check.schema)
      expect(schema[:required]).to eq(%w[findings])
      expect(schema.dig(:properties, :sources, :items, :properties, :reliability, :enum))
        .to include('unreliable')
    end

    it 'has a schema field for every artifact a check names' do
      named = ArticleAuditing::Registry.keys.map { |key| ArticleAuditing::Registry.check(key) }
                                       .grep(described_class).flat_map { |c| c.class::ARTIFACTS }
      expect(named).to match_array(ArticleAuditing::LlmOutputSchema::ARTIFACTS.keys.map(&:to_s))
    end

    it 'returns only its own artifacts' do
      json = { 'findings' => [], 'notability' => { 'assessment' => 'unclear' },
               'sources' => [] }
      allow(adapter).to receive(:complete)
        .and_return(llm_response.with(json:))
      output = ArticleAuditing::Checks::Notability.new.run(context)
      expect(output.artifacts).to eq('notability' => { 'assessment' => 'unclear' })
    end
  end

  describe 'checks that apply only to some pages' do
    def page(mainspace:, new_article: false, wikitext: '')
      instance_double(ArticleAuditing::Context, mainspace?: mainspace, new_article?: new_article,
                                                wikitext:)
    end

    it 'runs notability only on new articles' do
      check = ArticleAuditing::Checks::Notability.new
      expect(check.applies_to?(page(mainspace: false, new_article: true))).to be(true)
      expect(check.applies_to?(page(mainspace: false))).to be(false)
      expect(check.applies_to?(page(mainspace: true))).to be(false)
    end

    it 'proposes a short description for new articles and articles that lack one' do
      check = ArticleAuditing::Checks::ShortDescription.new
      expect(check.applies_to?(page(mainspace: false, new_article: true))).to be(true)
      expect(check.applies_to?(page(mainspace: true, wikitext: 'Text'))).to be(true)
      described = page(mainspace: true, wikitext: '{{Short description|Cat}} Text')
      expect(check.applies_to?(described)).to be(false)
      expect(check.applies_to?(page(mainspace: false, wikitext: 'Draft of an existing article')))
        .to be(false)
    end
  end

  describe 'checks that send gathered wiki data' do
    let(:wiki_context) { instance_double(ArticleAuditing::WikiContext, target_title: 'Topic') }

    before { allow(context).to receive(:wiki_context).and_return(wiki_context) }

    it 'sends existing-coverage search results after the prompt' do
      allow(wiki_context).to receive(:related_articles).and_return([
        { title: 'Topic (film)', description: 'A film', extract: 'Topic is a 2001 film.' }
      ])
      check = ArticleAuditing::Checks::ExistingCoverage.new
      check.run(context)
      expect(adapter).to have_received(:complete).with(hash_including(user: a_string_including(
        check.prompt, '<result title="Topic (film)" description="A film">', 'Topic is a 2001 film.'
      )))
    end

    it 'sends candidate categories and marks proposed categories that do not exist' do
      allow(context).to receive(:parsed_wikitext)
        .and_return(ArticleAuditing::Wikitext.new('See [[Cats]] and [[Dogs]]. [[Category:Pets]]'))
      allow(wiki_context).to receive(:category_counts).with(%w[Cats Dogs])
                                                       .and_return('Category:Mammals' => 2)
      allow(wiki_context).to receive(:existing_titles).and_return('Category:Mammals' => {})
      allow(adapter).to receive(:complete).and_return(llm_response.with(json: {
        'findings' => [], 'categories' => [{ 'name' => 'Mammals', 'reason' => 'r' },
                                           { 'name' => 'Made up', 'reason' => 'r' }]
      }))
      output = ArticleAuditing::Checks::Categories.new.run(context.tap do |c|
        allow(c).to receive(:wikitext).and_return('[[Category:Pets]]')
      end)
      expect(adapter).to have_received(:complete)
        .with(hash_including(user: a_string_including('Category:Mammals (2)', 'Category:Pets')))
      expect(output.artifacts['categories'].map { |c| c['exists'] }).to eq([true, false])
      expect(output.usage['nonexistent_categories']).to eq(1)
    end
  end
end
