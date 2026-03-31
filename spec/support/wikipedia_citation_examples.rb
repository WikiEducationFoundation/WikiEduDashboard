# frozen_string_literal: true

# Real Wikipedia URLs used as integration test fixtures for the
# WikipediaClaim / WikipediaSource / WikipediaCitation domain classes
# and the ExtractClaimsAndSources service.
#
# Each entry has:
#   description:  human-readable label used as the RSpec context string
#   url:          Wikipedia diff or revision URL passed to ExtractClaimsAndSources
#   cassette:     VCR cassette path (relative to fixtures/vcr_cassettes/)
#   expected:     optional assertions specific to this URL's content; any key
#                 that is absent is simply skipped by the corresponding it block.
#
#     source_claim_pairs_added: Integer  — exact number of WikipediaCitations expected
#     claim:        String               — substring that must appear in at least one claim
#     source:       String               — substring that must appear in at least one source's raw_text
#     source_urls:         Array<String>  — exact ordered list of source URLs across all citations
#     cs1_source_count:    Integer        — number of sources that have a COinS span (CS1 template)
#     source_genres:       Array<String>  — ordered list of rft.genre values across all citations
WIKIPEDIA_CITATION_EXAMPLES = [
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
      claim:            'they may privilege certain social groups',
      cs1_source_count: 2,
      source_genres:    %w[book book]
    }
  },
  {
    description: '3M_contamination_of_Minnesota_groundwater (diff=prev, rev 1315795891)',
    # From check_revision_with_pangram_spec.rb
    url: 'https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891',
    cassette: 'extract_claims_and_sources/3m_contamination_diff_prev',
    expected: {
      source_claim_pairs_added: 2,
      source_urls: [
        'https://doi.org/10.3133/wri844188a',
        'https://ir.library.oregonstate.edu/challenge?dest=/concern/graduate_projects/kk91ft133'
      ],
      cs1_source_count: 2,
      source_genres:    %w[report unknown]
    }
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
