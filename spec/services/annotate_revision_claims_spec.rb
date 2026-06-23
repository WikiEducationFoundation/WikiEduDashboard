# frozen_string_literal: true

require 'rails_helper'

describe AnnotateRevisionClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:article) do
    create(:article, wiki:, title: 'Sea otter', namespace: Article::Namespaces::MAINSPACE)
  end
  let(:mw_rev_id) { 777 }

  # Full flagged-revision HTML: one sentence that was added (and harvested) and
  # one pre-existing cited sentence that was not harvested in this revision.
  let(:revision_html) do
    <<~HTML
      <p>Sea otters use rocks as tools.<sup class="reference"><a href="#cite_note-added-1">[1]</a></sup>
      Otters are mammals.<sup class="reference"><a href="#cite_note-old-2">[2]</a></sup></p>
      <ol class="references">
        <li id="cite_note-added-1"><span class="reference-text"><cite>
          <a class="external" href="https://example.com/otters">Riedman 1990</a></cite></span></li>
        <li id="cite_note-old-2"><span class="reference-text"><cite>
          <a class="external" href="https://example.com/mammals">Mammals</a></cite></span></li>
      </ol>
    HTML
  end

  let!(:harvested) do
    VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: 'cite_note-added-1',
                              sentence: 'Sea otters use rocks as tools.', cite_text: 'Riedman 1990',
                              source_url: 'https://example.com/otters')
  end

  before do
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: revision_html))
  end

  def annotate
    described_class.new(article:, mw_rev_id:)
  end

  it 'renders the flagged revision in full (not the current article)' do
    annotate
    expect(GetRevisionHtmlWithCitations).to have_received(:new)
      .with(mw_rev_id, wiki, diff_mode: false)
  end

  it 'wraps the harvested claim in a cv-claim span carrying its claim id' do
    html = annotate.html
    expect(html).to include('cv-claim')
    expect(html).to include(%(data-claim-id="#{harvested.id}"))
    expect(html).to include('Sea otters use rocks as tools.')
  end

  it 'highlights only the claims harvested from this revision' do
    highlighted = Nokogiri::HTML.fragment(annotate.html).css('.cv-claim').map(&:text).join(' ')
    expect(highlighted).to include('Sea otters use rocks as tools.')
    expect(highlighted).not_to include('Otters are mammals.')
  end

  it 'returns no html when the revision has no harvested claims' do
    expect(described_class.new(article:, mw_rev_id: 999).html).to be_nil
  end
end
