# frozen_string_literal: true

# Helper for specs that loop over WIKIPEDIA_CITATION_EXAMPLES.
# Rescues any RSpec expectation failure and re-raises it with the entry's
# description prepended, so it's always clear which example caused the failure.
module WikipediaCitationExamplesHelper
  def with_entry(entry)
    yield
  rescue RSpec::Expectations::ExpectationNotMetError => e
    raise e.class, "#{entry[:description]}\n#{e.message}", e.backtrace
  end
end

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
#     source:       String  — substring that must appear in at least one source's raw_text
#     cs1_source_count:  Integer  — number of sources with a COinS span (CS1 template)
#     pairs:             Array    — per-pair assertions, ordered to match the diff; each entry
#                                  is a hash with any subset of:
#       claim:   String  — substring that must appear in this citation's claim text
#       pages:   String  — exact value of WikipediaCitation#pages (e.g. "365-367")
#       source:  Hash    — attributes of the WikipediaSource for this pair:
#         genre: String  — rft.genre from COinS (e.g. "book", "report", "unknown")
#         url:   String  — source URL, or nil for sources with no URL
WIKIPEDIA_CITATION_EXAMPLES = [
  # diff=prev URLs — exercises action=compare → wikitext extraction → action=parse
  {
    description: 'Third_place (diff=prev, rev 1340536495)',
    # From get_revision_plaintext.rb service comment and get_revision_plaintext_spec.rb.
    # Known to add sentences about online forums as third places, with citations.
    url: 'https://en.wikipedia.org/w/index.php?title=Third_place&diff=prev&oldid=1340536495',
    cassette: 'extract_claims_and_sources/third_place_diff_prev',
    expected: {
      # The diff modifies one existing paragraph (adding uncited sentences at
      # the end) and adds two new Criticism paragraphs, each with one citation.
      # Only the two new paragraphs produce pairs; the modified paragraph's
      # <ins> text has no citation following it.
      source_claim_pairs_added: 2,
      cs1_source_count: 2,
      pairs: [
        { claim: 'they may privilege certain social groups', source: { genre: 'book' } },
        { source: { genre: 'book' } }
      ]
    }
  },
  {
    description: '3M_contamination_of_Minnesota_groundwater (diff=prev, rev 1315795891)',
    # From check_revision_with_pangram_spec.rb
    url: 'https://en.wikipedia.org/w/index.php?title=3M_contamination_of_Minnesota_groundwater&diff=prev&oldid=1315795891',
    cassette: 'extract_claims_and_sources/3m_contamination_diff_prev',
    expected: {
      source_claim_pairs_added: 2,
      cs1_source_count: 2,
      pairs: [
        { source: { genre: 'report', url: 'https://doi.org/10.3133/wri844188a' } },
        { source: { genre: 'unknown', url: 'https://ir.library.oregonstate.edu/challenge?dest=/concern/graduate_projects/kk91ft133' } }
      ]
    }
  },
  {
    description: 'Richard_G._F._Uniacke (diff=prev, rev 936368512)',
    # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
    # The revision adds one sentence citing Burke's Landed Gentry — a print-only
    # reference (no URL) identified solely by ISBN and page number. Good for
    # testing that sources with an ISBN but no URL are handled cleanly.
    url: 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512',
    cassette: 'extract_claims_and_sources/richard_uniacke_diff_prev',
    expected: {
      source_claim_pairs_added: 1,
      cs1_source_count: 1,
      pairs: [
        {
          pages:  '1153',
          source: { genre: 'book', url: nil, isbn: '0-85011-050-5' }
        }
      ]
    }
  },
  {
    description: 'Eva_Hesse (diff=prev, rev 655980945)',
    # From alert.rb as an example diff URL for generating alerts.
    # The diff adds " on January 11, 1936" (a mid-sentence <ins>) immediately
    # followed by a new <ref> to the Encyclopedia of World Biography. Because
    # it's a mid-sentence fragment with no preceding sentence-ending punctuation,
    # last_sentence returns the whole accumulated text up to the citation.
    # The citation itself carries page numbers (365-367), making it a good
    # example for testing WikipediaCitation#pages.
    url: 'https://en.wikipedia.org/w/index.php?title=Eva_Hesse&diff=prev&oldid=655980945',
    cassette: 'extract_claims_and_sources/eva_hesse_diff_prev',
    expected: {
      source_claim_pairs_added: 1,
      cs1_source_count: 1,
      pairs: [
        {
          claim:  'January 11, 1936',
          pages:  '365-367',
          source: { genre: 'book', url: nil } # book with no URL; cited by page number only
        }
      ]
    }
  },
  {
    description: 'Vectors_in_gene_therapy (diff=prev, rev 637221390)',
    # From alert_spec.rb as an expected diff URL for a mainspace alert
    # The revision modifies sentence structure but adds no new inline citations,
    # so the service should return an empty array. Exercises the zero-pair path
    # for a mainspace article diff.
    url: 'https://en.wikipedia.org/w/index.php?title=Vectors_in_gene_therapy&diff=prev&oldid=637221390',
    cassette: 'extract_claims_and_sources/vectors_gene_therapy_diff_prev',
    expected: {
      source_claim_pairs_added: 0
    }
  },
  {
    description: 'Talk:Selfie (diff=prev, rev 637221390)',
    # From alert_spec.rb; talk page unlikely to have cited prose.
    # Talk-page edits are discussion, not article prose, so they never contain
    # inline CS1 citations. Verifies the zero-pair path for a non-mainspace URL.
    url: 'https://en.wikipedia.org/w/index.php?title=Talk:Selfie&diff=prev&oldid=637221390',
    cassette: 'extract_claims_and_sources/selfie_talk_diff_prev',
    expected: {
      source_claim_pairs_added: 0
    }
  },
  {
    description: 'User:Resekorynta/Evaluate_an_Article (diff=prev, rev 1315967896)',
    # From check_revision_with_pangram_spec.rb; user sandbox.
    # User-namespace draft with no cited prose — verifies graceful handling of
    # user-namespace pages where students stage edits before moving to mainspace.
    url: 'https://en.wikipedia.org/w/index.php?title=User:Resekorynta/Evaluate_an_Article&diff=prev&oldid=1315967896',
    cassette: 'extract_claims_and_sources/evaluate_article_diff_prev',
    expected: {
      source_claim_pairs_added: 0
    }
  },
  # Explicit diff range — both "to" and "from" revisions given; no parent lookup needed
  {
    description: 'Richard_G._F._Uniacke (diff range: rev 711811679 to 1178859026)',
    # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
    # Explicit diff range URL (?diff=<new>&oldid=<old>) for the same article and
    # same Burke's Landed Gentry citation as the diff=prev entry above. The two
    # URL forms should produce identical output; no parent-revision API call is
    # needed since both revisions are specified directly.
    url: 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=1178859026&oldid=711811679',
    cassette: 'extract_claims_and_sources/richard_uniacke_diff_range',
    expected: {
      source_claim_pairs_added: 1,
      cs1_source_count: 1,
      pairs: [
        { pages: '1153', source: { genre: 'book', url: nil } }
      ]
    }
  },
  # diff= with no oldid — @from_rev is nil so the service falls back to fetching
  # the full revision HTML via action=parse
  {
    description: 'List_of_hystricids (diff=1315039613, no oldid)',
    # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
    # diff= with no oldid: @from_rev is nil, so the service fetches the full
    # revision HTML rather than a diff. The article is a species list heavily
    # sourced from IUCN Red List entries and mammal handbooks; 15 claim-source
    # pairs are extracted, with a mix of article and book genres, named authors,
    # and ISBNs. Contrast with the oldid= entry below (revision_no_title), where
    # the same revision ID processed as a diff=prev yields 0 pairs.
    url: 'https://en.wikipedia.org/w/index.php?title=List_of_hystricids&diff=1315039613',
    cassette: 'extract_claims_and_sources/hystricids_diff_no_oldid',
    expected: {
      source_claim_pairs_added: 15,
      cs1_source_count: 15
    }
  },
  {
    description: 'no title, no oldid (diff=1315039613)',
    # From ai_tools_controller_spec.rb and wiki_url_parser_spec.rb
    # Same revision as the hystricids entry above but with the title= parameter
    # omitted entirely. The service resolves the page via the API and falls back
    # to fetching full revision HTML, producing the same 15 pairs. Verifies that
    # the title-less URL form is handled identically to the titled form.
    url: 'https://en.wikipedia.org/w/index.php?diff=1315039613',
    cassette: 'extract_claims_and_sources/diff_no_title',
    expected: {
      source_claim_pairs_added: 15,
      cs1_source_count: 15
    }
  },
  # Article revision URLs (oldid only, no diff=) — treated as diff=prev internally:
  # the service fetches the parent and compares the named revision against it
  {
    description: 'List_of_the_busiest_airports_in_Malaysia (oldid=1276659876)',
    # From wiki_url_parser_spec.rb and ai_tools_controller_spec.rb
    # The revision updates rows in a table of airport statistics. Because the
    # added content is tabular rather than cited prose, no claim-source pairs
    # are produced. Exercises the zero-pair path for a table-heavy list article.
    url: 'https://en.wikipedia.org/w/index.php?title=List_of_the_busiest_airports_in_Malaysia&oldid=1276659876',
    cassette: 'extract_claims_and_sources/busiest_airports_malaysia_revision',
    expected: {
      source_claim_pairs_added: 0
    }
  },
  {
    description: 'revision with no title (oldid=1315039613)',
    # From wiki_url_parser_spec.rb and ai_tools_controller_spec.rb
    # oldid= with no title for the same revision ID as the hystricids entries
    # above. With oldid= the service performs a diff=prev against the parent
    # revision rather than fetching full HTML. That diff adds 0 new cited
    # sentences — in contrast to the 15 pairs produced by ?diff=1315039613.
    # Illustrates how the same revision ID yields very different results
    # depending on whether it appears as diff= or oldid=.
    url: 'https://en.wikipedia.org/w/index.php?oldid=1315039613',
    cassette: 'extract_claims_and_sources/revision_no_title',
    expected: {
      source_claim_pairs_added: 0
    }
  },
  {
    description: 'User:100110Z/Five-a-side_football (oldid=1327139425)',
    # From check_revision_with_pangram_spec.rb; user-space draft.
    # oldid= for a user-space draft of a Five-a-side football article. The
    # revision adds prose to the sandbox but the diff against its parent adds
    # no new inline citations, so no pairs are produced.
    url: 'https://en.wikipedia.org/w/index.php?title=User:100110Z/Five-a-side_football&oldid=1327139425',
    cassette: 'extract_claims_and_sources/five_a_side_football_revision',
    expected: {
      source_claim_pairs_added: 0
    }
  }
].freeze
