# frozen_string_literal: true

require 'rails_helper'

describe ExtractArticleClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) do
    create(:article, wiki:, title: 'Otter', namespace: Article::Namespaces::MAINSPACE)
  end

  let(:html) do
    <<~HTML
      <p>Otters use tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Otters</a></cite></span></li></ol>
    HTML
  end

  before do
    article_content = instance_double(WikiApi::ArticleContent, latest_revision_id: 777)
    allow(WikiApi::ArticleContent).to receive(:new).and_return(article_content)
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html:))
  end

  it 'extracts the cited claims and citations in memory' do
    result = described_class.new(article)
    expect(result.claims.map(&:sentence)).to eq(['Otters use tools.'])
    expect(result.citations.map(&:ref_id)).to eq(['cite_note-1'])
    expect(result.mw_rev_id).to eq(777)
  end

  it 'persists nothing' do
    expect { described_class.new(article) }.not_to change(VerificationClaim, :count)
  end

  it 'exposes the article prose paragraphs for the highlighted view' do
    expect(described_class.new(article).paragraphs.first.first[:sentence])
      .to eq('Otters use tools.')
  end
end
