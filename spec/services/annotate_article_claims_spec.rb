# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

describe AnnotateArticleClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) do
    create(:article, wiki:, title: 'Otter', namespace: Article::Namespaces::MAINSPACE)
  end

  let(:source_html) do
    <<~HTML
      <p>Otters use tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup>
      An uncited remark about <a href="/wiki/Sea_otter">sea otters</a>.</p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Otters</a></cite></span></li></ol>
    HTML
  end

  before do
    article_content = instance_double(WikiApi::ArticleContent, latest_revision_id: 999)
    allow(WikiApi::ArticleContent).to receive(:new).and_return(article_content)
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: source_html))
  end

  it 'wraps the cited claim sentence in a span with class and data' do
    claim = Nokogiri::HTML.fragment(described_class.new(article).html)
                          .at_css('.cv-claim')
    expect(claim.name).to eq('span')
    # The span covers the whole sentence, not just the [n] marker, and stops at
    # the sentence boundary (the following uncited sentence is left out).
    expect(claim.text.strip).to eq('Otters use tools.')
    expect(claim['data-ref-id']).to eq('cite_note-1')
    expect(claim['data-sentence']).to eq('Otters use tools.')
    expect(claim['data-source-url']).to eq('https://example.com/otters')
  end

  it 'highlights only the cited sentence in a multi-sentence paragraph' do
    paragraph = '<p>An uncited claim. A cited one.' \
                '<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>' \
                '<ol class="references"><li id="cite_note-1"><span class="reference-text">' \
                '<cite><a class="external" href="https://example.com/x">X</a></cite></span></li></ol>'
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: paragraph))
    claim = Nokogiri::HTML.fragment(described_class.new(article).html).at_css('.cv-claim')
    expect(claim.text.strip).to eq('A cited one.')
  end

  it 'leaves the article HTML otherwise intact (only the claim wrapped)' do
    html = described_class.new(article).html
    expect(html).to include('Otters use tools.')
    expect(html).to include('about')
    expect(html.scan('cv-claim').size).to eq(1)
  end

  it 'absolutizes root-relative wiki links but leaves in-page anchors alone' do
    html = described_class.new(article).html
    expect(html).to include('href="https://en.wikipedia.org/wiki/Sea_otter"')
    expect(html).to include('href="#cite_note-1"')
  end
end
