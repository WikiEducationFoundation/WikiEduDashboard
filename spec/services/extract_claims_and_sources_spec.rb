# frozen_string_literal: true

require 'rails_helper'

describe ExtractClaimsAndSources do
  wikipedia_urls = WIKIPEDIA_CITATION_EXAMPLES

  describe '#claims_and_sources' do
    def result_for(entry)
      VCR.use_cassette(entry[:cassette]) do
        described_class.new(entry[:url]).claims_and_sources
      end
    end

    it 'returns an Array for every URL' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry)).to be_an(Array)
      end
    end

    it 'has WikipediaCitation objects each with a claim and source' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry)).to all(
          have_attributes(claim: an_instance_of(WikipediaClaim),
                          source: an_instance_of(WikipediaSource))
        )
      end
    end

    it 'has non-blank string claim texts' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry).map { |c| c.claim.text }).to all(be_a(String).and(be_present))
      end
    end

    # Citation bracket markers like [1] should have been stripped when
    # converting the parsed HTML to plain text.
    it 'has claim texts free of leftover citation bracket markers' do
      wikipedia_urls.each do |entry|
        claims = result_for(entry).map { |c| c.claim.text }
        expect(claims).not_to include(a_string_matching(/\[\d+\]/))
      end
    end

    it 'has non-blank raw_text on every source' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry).map { |c| c.source.raw_text }).to all(be_a(String).and(be_present))
      end
    end

    it 'contains no duplicate claim-source pairs' do
      wikipedia_urls.each do |entry|
        pairs = result_for(entry).map { |c| [c.claim.text, c.source.raw_text] }
        expect(pairs.uniq).to eq(pairs)
      end
    end

    # Content-specific checks — only run for entries that declare an expectation.
    it 'returns exactly the expected number of pairs' do
      wikipedia_urls.select { |e| e[:expected].key?(:source_claim_pairs_added) }.each do |entry|
        expect(result_for(entry).size).to eq(entry[:expected][:source_claim_pairs_added])
      end
    end

    it 'includes the expected claim text in at least one claim' do
      wikipedia_urls.select { |e| e[:expected].key?(:claim) }.each do |entry|
        claims = result_for(entry).map { |c| c.claim.text }
        expect(claims).to include(a_string_including(entry[:expected][:claim]))
      end
    end

    it 'includes the expected text in at least one source' do
      wikipedia_urls.select { |e| e[:expected].key?(:source) }.each do |entry|
        sources = result_for(entry).map { |c| c.source.raw_text }
        expect(sources).to include(a_string_including(entry[:expected][:source]))
      end
    end

    it 'has sources whose URLs match the expected list exactly' do
      wikipedia_urls.select { |e| e[:expected].key?(:source_urls) }.each do |entry|
        urls = result_for(entry).map { |citation| citation.source.url }
        expect(urls).to eq(entry[:expected][:source_urls])
      end
    end
  end
end
