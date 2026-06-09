# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/claim_citation_extractor"

describe ClaimVerification::ClaimCitationExtractor do
  describe 'with real MediaWiki parser output' do
    # Parsed changed-wikitext of the Third_place diff (oldid=1340536495),
    # captured from the action=parse API.
    let(:html) do
      File.read("#{Rails.root}/fixtures/claim_verification_eval/third_place_diff.html")
    end
    let(:extractor) { described_class.new(html) }

    it 'extracts one citation per reference-list entry' do
      expect(extractor.citations.map(&:ref_id)).to eq(%w[cite_note-1 cite_note-2])
    end

    it 'extracts the cite text without style markup' do
      putnam = extractor.citations.first
      expect(putnam.cite_text).to include('Putnam, Robert D. (2000)')
      expect(putnam.cite_text).not_to include('mw-parser-output')
    end

    it 'reports book references without links as offline sources' do
      expect(extractor.citations).to all(be_offline_source)
    end

    it 'pairs each cited sentence with its reference' do
      cited_sentences = extractor.claims.map { |claim| [claim.sentence, claim.ref_ids] }
      expect(cited_sentences).to contain_exactly(
        [a_string_matching(/privilege certain social groups/), ['cite_note-1']],
        [a_string_matching(/may not be distributed evenly/), ['cite_note-2']]
      )
    end

    it 'does not create claims for uncited sentences' do
      sentences = extractor.claims.map(&:sentence)
      expect(sentences.join).not_to include('Scholars have noted that online forums')
    end

    it 'includes preceding paragraph text as claim context' do
      claim = extractor.claims.first
      expect(claim.context).to start_with('Some researchers argue')
      expect(claim.context).to end_with(claim.sentence)
    end

    it 'excludes figure captions from claims and context' do
      all_text = extractor.claims.map(&:context).join
      expect(all_text).not_to include('Coworking Space in Berlin')
    end
  end

  describe 'with citation URLs' do
    let(:html) do
      <<~HTML
        <p>The site opened in 1990.<sup class="reference" id="cite_ref-a_1-0">
          <a href="#cite_note-a-1">[1]</a></sup></p>
        <ol class="references">
          <li id="cite_note-a-1">
            <span class="mw-cite-backlink"><a href="#cite_ref-a_1-0">^</a></span>
            <span class="reference-text"><cite class="citation web cs1">
              <a class="external text" href="https://example.com/history">"History"</a>.
              <a class="external text"
                 href="https://web.archive.org/web/2024/https://example.com/history">Archived</a>
              from the original.</cite></span>
          </li>
        </ol>
      HTML
    end
    let(:citation) { described_class.new(html).citations.first }

    it 'separates archive URLs from source URLs' do
      expect(citation.urls).to eq(['https://example.com/history'])
      expect(citation.archive_urls)
        .to eq(['https://web.archive.org/web/2024/https://example.com/history'])
      expect(citation.offline_source?).to eq(false)
    end
  end

  describe 'with a bare ref (no cite element)' do
    let(:html) do
      <<~HTML
        <p>A fact.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
        <ol class="references">
          <li id="cite_note-1"><span class="reference-text">Just a bare note,
            see <a class="external free" href="http://example.org">http://example.org</a></span></li>
        </ol>
      HTML
    end

    it 'falls back to the reference text' do
      citation = described_class.new(html).citations.first
      expect(citation.cite_text).to include('Just a bare note')
      expect(citation.urls).to eq(['http://example.org'])
    end
  end

  describe 'claim segmentation' do
    let(:html) do
      <<~HTML
        <p>First fact.<sup class="reference"><a href="#cite_note-x-1">[1]</a></sup>
        Second fact, with detail.<sup class="reference"><a href="#cite_note-x-1">[1]</a></sup><sup
          class="reference"><a href="#cite_note-y-2">[2]</a></sup>
        An uncited remark.</p>
      HTML
    end
    let(:claims) { described_class.new(html).claims }

    it 'attaches multiple references to one sentence' do
      expect(claims.last.ref_ids).to eq(%w[cite_note-x-1 cite_note-y-2])
    end

    it 'keeps sentences separate' do
      expect(claims.map(&:sentence)).to eq(
        ['First fact.', 'Second fact, with detail.']
      )
    end
  end

  describe 'with no references' do
    it 'returns empty collections' do
      extractor = described_class.new('<p>Plain text only.</p>')
      expect(extractor.claims).to be_empty
      expect(extractor.citations).to be_empty
    end
  end
end
