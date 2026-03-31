# frozen_string_literal: true

require 'rails_helper'

describe WikipediaSource do
  # For each example, extract the WikipediaSource objects from the citations
  # returned by ExtractClaimsAndSources and run shared + content-specific checks.
  def sources_for(entry)
    VCR.use_cassette(entry[:cassette]) do
      ExtractClaimsAndSources.new(entry[:url]).claims_and_sources.map(&:source)
    end
  end

  describe 'sources extracted via ExtractClaimsAndSources' do
    it 'are all WikipediaSource instances' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        expect(sources_for(entry)).to all(be_a(described_class))
      end
    end

    it 'all have non-blank raw_text' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        expect(sources_for(entry).map(&:raw_text)).to all(be_a(String).and(be_present))
      end
    end

    it 'all have an Array for authors' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        expect(sources_for(entry).map(&:authors)).to all(be_an(Array))
      end
    end

    # COinS-specific checks — only meaningful for sources that use CS1 citation
    # templates (Citation Style 1: {{Cite book}}, {{Cite web}}, {{Cite journal}},
    # {{Cite report}}, etc. — see https://en.wikipedia.org/wiki/Help:Citation_Style_1).
    # All CS1 templates emit a <span class="Z3988"> containing COinS metadata
    # (structured bibliographic fields encoded in the title attribute), so
    # `genre.present?` serves as a reliable proxy for "was created with a CS1 template".

    it 'CS1 sources have a non-blank title' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        sources = sources_for(entry)
        cs1 = sources.select { |s| s.genre.present? }
        expect(cs1.map(&:title)).to all(be_a(String).and(be_present))
      end
    end

    it 'CS1 sources have a non-blank genre' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        sources = sources_for(entry)
        cs1 = sources.select { |s| s.genre.present? }
        expect(cs1.map(&:genre)).to all(be_a(String).and(be_present))
      end
    end

    it 'CS1 sources have a URL that is a String when present' do
      WIKIPEDIA_CITATION_EXAMPLES.each do |entry|
        sources = sources_for(entry)
        cs1 = sources.select { |s| s.genre.present? }
        cs1.each do |source|
          expect(source.url).to be_a(String).and(be_present) if source.url
        end
      end
    end

    # Content-specific checks — only run for entries that declare an expectation.

    it 'has the expected number of CS1 sources' do
      WIKIPEDIA_CITATION_EXAMPLES.select { |e| e[:expected].key?(:cs1_source_count) }
                                 .each do |entry|
        cs1_count = sources_for(entry).count { |s| s.genre.present? }
        expect(cs1_count).to eq(entry[:expected][:cs1_source_count])
      end
    end

    it 'has sources with the expected genres in order' do
      WIKIPEDIA_CITATION_EXAMPLES.select { |e| e[:expected].key?(:source_genres) }.each do |entry|
        genres = sources_for(entry).map(&:genre)
        expect(genres).to eq(entry[:expected][:source_genres])
      end
    end
  end

  # Detailed test for a specific known source, to verify that structured
  # COinS fields are parsed correctly into individual attributes.
  describe 'first source from 3M_contamination_of_Minnesota_groundwater diff' do
    # https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891
    # A {{Cite report}} citation for a US Geological Survey report, with a DOI URL
    # and no named authors (institutional authorship).
    let(:source) do
      entry = WIKIPEDIA_CITATION_EXAMPLES.find do |e|
        e[:description].include?('3M_contamination')
      end
      VCR.use_cassette(entry[:cassette]) do
        ExtractClaimsAndSources.new(entry[:url]).claims_and_sources.first.source
      end
    end

    it 'pretty prints all key fields' do
      puts source
    end

    it 'has genre "report"' do
      expect(source.genre).to eq('report')
    end

    it 'has the correct DOI url' do
      expect(source.url).to eq('https://doi.org/10.3133/wri844188a')
    end

    it 'has date "1984"' do
      expect(source.date).to eq('1984')
    end

    it 'has publisher "US Geological Survey"' do
      expect(source.publisher).to eq('US Geological Survey')
    end

    it 'has no named authors (institutional authorship)' do
      expect(source.authors).to be_empty
    end

    it 'has a title containing the report name' do
      expect(source.title).to include('Ground-water contamination by crude oil')
    end
  end
end
