# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_library/record"

# Builders for claim-library records, so each spec states only what it is
# about and not the whole record.
module ClaimLibraryHelper
  def library_record(**overrides)
    attributes = {
      wiki: 'en.wikipedia', article_title: 'Surrogacy in India', mw_rev_id: 1_321_874_993,
      ref_id: 'cite_note-:0-1',
      sentence: 'The Confederation of Indian Industry estimated the business at US$2.3 billion.',
      context: 'The market grew. The Confederation of Indian Industry estimated the business ' \
               'at US$2.3 billion.',
      citation: { 'text' => 'Hibino, Yuri (2023). "Altruistic and commercial surrogacy in India".',
                  'urls' => ['https://pmc.ncbi.nlm.nih.gov/articles/PMC10327345/'],
                  'archive_urls' => [], 'offline' => false }
    }
    ClaimLibrary::Record.new(**attributes.merge(overrides))
  end

  def judged_record(verdict: 'full_support', flags: [], **overrides)
    record = library_record(**overrides)
    record.judgment = ClaimLibrary::Judgment.new(
      verdict:, reason: 'The source gives the figure.', annotator: 'Moruri',
      passage: 'surrogacy generates US$2.3 billion annually', flags:
    )
    record
  end
end

RSpec.configure do |config|
  config.include ClaimLibraryHelper
end
