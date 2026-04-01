# frozen_string_literal: true

require 'rails_helper'

describe ExtractClaimsAndSources do
  include WikipediaCitationExamplesHelper

  wikipedia_urls = WIKIPEDIA_CITATION_EXAMPLES

  describe '#claims_and_sources' do
    def result_for(entry)
      VCR.use_cassette(entry[:cassette]) do
        described_class.new(entry[:url]).claims_and_sources
      end
    end

    it 'returns an Array for every URL' do
      wikipedia_urls.each do |entry|
        with_entry(entry) { expect(result_for(entry)).to be_an(Array) }
      end
    end

    it 'has WikipediaCitation objects each with a claim and source' do
      wikipedia_urls.each do |entry|
        with_entry(entry) do
          expect(result_for(entry)).to all(
            have_attributes(claim: an_instance_of(WikipediaClaim),
                            source: an_instance_of(WikipediaSource))
          )
        end
      end
    end

    it 'has non-blank string claim texts' do
      wikipedia_urls.each do |entry|
        with_entry(entry) do
          expect(result_for(entry).map { |c| c.claim.text }).to all(be_a(String).and(be_present))
        end
      end
    end

    # Citation bracket markers like [1] should have been stripped when
    # converting the parsed HTML to plain text.
    it 'has claim texts free of leftover citation bracket markers' do
      wikipedia_urls.each do |entry|
        with_entry(entry) do
          claims = result_for(entry).map { |c| c.claim.text }
          expect(claims).not_to include(a_string_matching(/\[\d+\]/))
        end
      end
    end

    it 'has non-blank raw_text on every source' do
      wikipedia_urls.each do |entry|
        with_entry(entry) do
          expect(result_for(entry).map { |c| c.source.raw_text }).to all(be_a(String).and(be_present))
        end
      end
    end

    it 'contains no duplicate claim-source pairs' do
      wikipedia_urls.each do |entry|
        with_entry(entry) do
          pairs = result_for(entry).map { |c| [c.claim.text, c.source.raw_text] }
          expect(pairs.uniq).to eq(pairs)
        end
      end
    end

    # Content-specific checks — only run for entries that declare an expectation.
    it 'returns exactly the expected number of pairs' do
      wikipedia_urls.select { |e| e[:expected].key?(:source_claim_pairs_added) }.each do |entry|
        with_entry(entry) do
          expect(result_for(entry).size).to eq(entry[:expected][:source_claim_pairs_added])
        end
      end
    end

    it 'matches all per-pair expected attributes' do
      wikipedia_urls.select { |e| e[:expected].key?(:pairs) }.each do |entry|
        citations = result_for(entry)
        entry[:expected][:pairs].each_with_index do |pair_exp, i|
          with_entry(entry) do
            citation = citations[i]
            expect(citation).not_to be_nil, "pair[#{i}] is nil (only #{citations.size} pairs returned)"
            expect(citation.claim.text).to include(pair_exp[:claim]) if pair_exp.key?(:claim)
            expect(citation.pages).to eq(pair_exp[:pages]) if pair_exp.key?(:pages)
            next unless pair_exp.key?(:source)

            src_exp = pair_exp[:source]
            expect(citation.source.genre).to eq(src_exp[:genre]) if src_exp.key?(:genre)
            expect(citation.source.url).to eq(src_exp[:url]) if src_exp.key?(:url)
          end
        end
      end
    end
  end
end
