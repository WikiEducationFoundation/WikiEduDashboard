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

  # A named ref like <ref name="O'Brien 2020"> renders with the apostrophe kept in
  # the cite_note id, which used to break the interpolated CSS selector that
  # located the marker (Nokogiri::CSS::SyntaxError, 500ing the endpoint).
  context 'when a harvested claim cites a ref whose id contains an apostrophe' do
    let(:revision_html) do
      <<~HTML
        <p>Otters were studied for years.<sup class="reference"><a href="#cite_note-O'Brien_2020-1">[1]</a></sup></p>
        <ol class="references">
          <li id="cite_note-O'Brien_2020-1"><span class="reference-text"><cite>
            <a class="external" href="https://example.com/obrien">O'Brien 2020</a></cite></span></li>
        </ol>
      HTML
    end
    let!(:harvested) do
      VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: "cite_note-O'Brien_2020-1",
                                sentence: 'Otters were studied for years.',
                                cite_text: "O'Brien 2020", source_url: 'https://example.com/obrien')
    end

    it 'highlights the claim without raising' do
      html = annotate.html
      expect(html).to include('cv-claim')
      expect(html).to include(%(data-claim-id="#{harvested.id}"))
      expect(html).to include('Otters were studied for years.')
    end
  end

  # The bug this guards: a source cited on several sentences renders the same
  # cite_note href at every one of them, and locating a claim by its marker
  # attached each claim's data to the *first* of those sentences — so the
  # highlighted text was not the claim that came up when you clicked it.
  context 'when one source is cited on several sentences' do
    # The first sentence is deliberately long: locating a claim by walking back
    # from the first marker sharing its ref id then finds plenty of prose to
    # consume, and so silently succeeds on the wrong sentence.
    let(:revision_html) do
      <<~HTML
        <p>Otters were studied extensively throughout the twentieth century by many
        researchers.<sup class="reference"><a href="#cite_note-shared-1">[1]</a></sup>
        Otters eat urchins.<sup class="reference"><a href="#cite_note-shared-1">[1]</a></sup>
        Otters have dense fur.<sup class="reference"><a href="#cite_note-shared-1">[1]</a></sup></p>
        <ol class="references">
          <li id="cite_note-shared-1"><span class="reference-text"><cite>
            <a class="external" href="https://example.com/r">Riedman 1990</a></cite></span></li>
        </ol>
      HTML
    end
    # Only the second and third sentences were added in this revision.
    let!(:harvested) do
      VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: 'cite_note-shared-1',
                                sentence: 'Otters eat urchins.', cite_text: 'Riedman 1990',
                                source_url: 'https://example.com/r')
    end
    let!(:other) do
      VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: 'cite_note-shared-1',
                                sentence: 'Otters have dense fur.', cite_text: 'Riedman 1990',
                                source_url: 'https://example.com/r')
    end

    def span_for(html, claim)
      Nokogiri::HTML.fragment(html).at_css(%(.cv-claim[data-claim-id="#{claim.id}"]))
    end

    it 'highlights the text of each claim, not the first sentence citing the source' do
      html = annotate.html
      expect(span_for(html, harvested).text).to include('Otters eat urchins.')
      expect(span_for(html, other).text).to include('Otters have dense fur.')
    end

    it 'agrees with the claim data behind every highlight' do
      spans = Nokogiri::HTML.fragment(annotate.html).css('.cv-claim')
      expect(spans).not_to be_empty
      spans.each do |span|
        expect(span.text.gsub(/\[\d+\]|\s+/, ' ').squeeze(' ').strip)
          .to include(span['data-sentence'])
      end
    end

    it 'leaves the sentence that was not harvested unhighlighted' do
      highlighted = Nokogiri::HTML.fragment(annotate.html).css('.cv-claim').map(&:text).join(' ')
      expect(highlighted).not_to include('studied extensively')
    end
  end

  # A citation can sit inside a sentence rather than at its end, which a
  # marker-relative search could never cover: the sentence continues past it.
  context 'when the citation sits mid-sentence' do
    let(:revision_html) do
      <<~HTML
        <p>Otters use rocks<sup class="reference"><a href="#cite_note-r-1">[1]</a></sup>, and they eat urchins.</p>
        <ol class="references">
          <li id="cite_note-r-1"><span class="reference-text"><cite>
            <a class="external" href="https://example.com/r">Riedman</a></cite></span></li>
        </ol>
      HTML
    end
    let!(:harvested) do
      VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: 'cite_note-r-1',
                                sentence: 'Otters use rocks, and they eat urchins.',
                                cite_text: 'Riedman', source_url: 'https://example.com/r')
    end

    it 'highlights the whole sentence, both sides of the citation' do
      span = Nokogiri::HTML.fragment(annotate.html).at_css('.cv-claim')
      expect(span.text).to include('Otters use rocks')
      expect(span.text).to include('and they eat urchins.')
    end
  end

  context 'when the revision links to other pages' do
    let(:revision_html) do
      <<~HTML
        <p>Otters use rocks.<sup class="reference"><a href="#cite_note-r-1">[1]</a></sup>
        See <a href="/wiki/Sea_otter">Sea otter</a> and
        <a href="//upload.wikimedia.org/otter.jpg">a photo</a>.</p>
        <ol class="references">
          <li id="cite_note-r-1"><span class="reference-text"><cite>
            <a class="external" href="https://example.com/r">Riedman</a></cite></span></li>
        </ol>
      HTML
    end
    let!(:harvested) do
      VerificationClaim.create!(wiki:, article:, mw_rev_id:, ref_id: 'cite_note-r-1',
                                sentence: 'Otters use rocks.', cite_text: 'Riedman',
                                source_url: 'https://example.com/r')
    end

    it 'absolutizes root-relative links but leaves protocol-relative ones alone' do
      html = annotate.html
      expect(html).to include(%(href="#{wiki.base_url}/wiki/Sea_otter"))
      expect(html).to include('href="//upload.wikimedia.org/otter.jpg"')
    end
  end
end
