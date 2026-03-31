# frozen_string_literal: true

require 'rails_helper'

describe ExtractClaimsAndSources do
  # URLs sourced from comments and existing specs throughout the codebase.
  # Defined as a local variable (not a constant) to avoid re-initialization
  # errors if the spec file is loaded more than once.
  # Each entry is tested uniformly: claims and sources are checked for
  # well-formedness rather than for any particular content.
  wikipedia_urls = [
    # diff=prev URLs — exercises action=compare → wikitext extraction → action=parse
    {
      description: 'Third_place (diff=prev, rev 1340536495)',
      # From get_revision_plaintext.rb service comment and get_revision_plaintext_spec.rb.
      # Known to add sentences about online forums as third places, with citations.
      url: 'https://en.wikipedia.org/w/index.php?title=Third_place&diff=prev&oldid=1340536495',
      cassette: 'extract_claims_and_sources/third_place_diff_prev',
      expected: {
        source_claim_pairs_added: 2,
        # The diff modifies one existing paragraph (adding uncited sentences at
        # the end) and adds two new Criticism paragraphs, each with one citation.
        # Only the two new paragraphs produce pairs; the modified paragraph's
        # <ins> text has no citation following it.
        claim: 'they may privilege certain social groups'
      }
    },
    {
      description: '3M_contamination_of_Minnesota_groundwater (diff=prev, rev 1315795891)',
      # From check_revision_with_pangram_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891',
      cassette: 'extract_claims_and_sources/3m_contamination_diff_prev',
      expected: {}
    },
    {
      description: 'Richard_G._F._Uniacke (diff=prev, rev 936368512)',
      # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512',
      cassette: 'extract_claims_and_sources/richard_uniacke_diff_prev',
      expected: {}
    },
    {
      description: 'Eva_Hesse (diff=prev, rev 655980945)',
      # From alert.rb as an example diff URL for generating alerts
      url: 'https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945',
      cassette: 'extract_claims_and_sources/eva_hesse_diff_prev',
      expected: {}
    },
    {
      description: 'Vectors_in_gene_therapy (diff=prev, rev 637221390)',
      # From alert_spec.rb as an expected diff URL for a mainspace alert
      url: 'https://en.wikipedia.org/w/index.php?title=Vectors_in_gene_therapy&diff=prev&oldid=637221390',
      cassette: 'extract_claims_and_sources/vectors_gene_therapy_diff_prev',
      expected: {}
    },
    {
      description: 'Talk:Selfie (diff=prev, rev 637221390)',
      # From alert_spec.rb; talk page unlikely to have cited prose
      url: 'https://en.wikipedia.org/w/index.php?title=Talk:Selfie&diff=prev&oldid=637221390',
      cassette: 'extract_claims_and_sources/selfie_talk_diff_prev',
      expected: {}
    },
    {
      description: 'User:Resekorynta/Evaluate_an_Article (diff=prev, rev 1315967896)',
      # From check_revision_with_pangram_spec.rb; user sandbox
      url: 'https://en.wikipedia.org/w/index.php?title=User:Resekorynta/Evaluate_an_Article&diff=prev&oldid=1315967896',
      cassette: 'extract_claims_and_sources/evaluate_article_diff_prev',
      expected: {}
    },
    # Explicit diff range — both "to" and "from" revisions given; no parent lookup needed
    {
      description: 'Richard_G._F._Uniacke (diff range: rev 711811679 to 1178859026)',
      # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=1178859026&oldid=711811679',
      cassette: 'extract_claims_and_sources/richard_uniacke_diff_range',
      expected: {}
    },
    # diff= with no oldid — @from_rev is nil so the service falls back to fetching
    # the full revision HTML via action=parse
    {
      description: 'List_of_hystricids (diff=1315039613, no oldid)',
      # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?title=List_of_hystricids&diff=1315039613',
      cassette: 'extract_claims_and_sources/hystricids_diff_no_oldid',
      expected: {}
    },
    {
      description: 'no title, no oldid (diff=1315039613)',
      # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?diff=1315039613',
      cassette: 'extract_claims_and_sources/diff_no_title',
      expected: {}
    },
    # Article revision URLs (oldid only, no diff=) — treated as diff=prev internally:
    # the service fetches the parent and compares the named revision against it
    {
      description: 'List_of_the_busiest_airports_in_Malaysia (oldid=1276659876)',
      # From wiki_url_parser_spec.rb and ai_tools_controller_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?title=List_of_the_busiest_airports_in_Malaysia&oldid=1276659876',
      cassette: 'extract_claims_and_sources/busiest_airports_malaysia_revision',
      expected: {}
    },
    {
      description: 'revision with no title (oldid=1315039613)',
      # From wiki_url_parser_spec.rb and ai_tools_controller_spec.rb
      url: 'https://en.wikipedia.org/w/index.php?oldid=1315039613',
      cassette: 'extract_claims_and_sources/revision_no_title',
      expected: {}
    },
    {
      description: 'User:100110Z/Five-a-side_football (oldid=1327139425)',
      # From check_revision_with_pangram_spec.rb; user-space draft
      url: 'https://en.wikipedia.org/w/index.php?title=User:100110Z/Five-a-side_football&oldid=1327139425',
      cassette: 'extract_claims_and_sources/five_a_side_football_revision',
      expected: {}
    }
  ].freeze

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

    it 'has pairs each containing :claim and :source keys' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry)).to all(include(:claim, :source))
      end
    end

    it 'has non-blank string claims' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry).map { |pair| pair[:claim] }).to all(be_a(String).and(be_present))
      end
    end

    # Citation bracket markers like [1] should have been stripped when
    # converting the parsed HTML to plain text.
    it 'has claims free of leftover citation bracket markers' do
      wikipedia_urls.each do |entry|
        claims = result_for(entry).map { |pair| pair[:claim] }
        expect(claims).not_to include(a_string_matching(/\[\d+\]/))
      end
    end

    it 'has non-blank string sources' do
      wikipedia_urls.each do |entry|
        expect(result_for(entry).map { |pair| pair[:source] }).to all(be_a(String).and(be_present))
      end
    end

    it 'contains no duplicate claim-source pairs' do
      wikipedia_urls.each do |entry|
        pairs = result_for(entry).map { |pair| [pair[:claim], pair[:source]] }
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
        claims = result_for(entry).map { |pair| pair[:claim] }
        expect(claims).to include(a_string_including(entry[:expected][:claim]))
      end
    end

    it 'includes the expected text in at least one source' do
      wikipedia_urls.select { |e| e[:expected].key?(:source) }.each do |entry|
        sources = result_for(entry).map { |pair| pair[:source] }
        expect(sources).to include(a_string_including(entry[:expected][:source]))
      end
    end

    it 'includes the expected URL in at least one source' do
      wikipedia_urls.select { |e| e[:expected].key?(:source_url) }.each do |entry|
        sources = result_for(entry).map { |pair| pair[:source] }
        expect(sources).to include(a_string_including(entry[:expected][:source_url]))
      end
    end
  end
end
