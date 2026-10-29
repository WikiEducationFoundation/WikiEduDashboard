# frozen_string_literal: true

# Fact Verification exercise: every student response, with its claim and source.
#
# For choosing items for a source-verification pre/post instrument: merged locally
# with the staff verdicts in the Fall 2026 curation spreadsheet (by claim id), this
# shows how often students called a claim fully supported when staff did not, and
# what they pointed to in the source when they did (claim_location).
#
# No student identity is exported — responses carry only their course id.
#
# Paste into a production Rails console. Writes the CSV to FV_RESPONSES_CSV
# (default: ~/fv_responses.csv).

require 'csv'

output_path = ENV.fetch('FV_RESPONSES_CSV', File.join(Dir.home, 'fv_responses.csv'))

headers = %w[response_id course_id created_at claim_id article_title sentence source_url
             archive_url cite_text source_access verdict claim_location verification_notes
             other_comments]

CSV.open(output_path, 'w') do |csv|
  csv << headers
  VerificationClaimResponse.includes(:verification_claim).find_each do |response|
    claim = response.verification_claim
    csv << [response.id, response.course_id, response.created_at, claim.id, claim.article_title,
            claim.sentence, claim.source_url, claim.archive_url, claim.cite_text,
            response.answer(:source_access), response.answer(:verdict),
            response.answer(:claim_location), response.answer(:verification_notes),
            response.answer(:other_comments)]
  end
end

puts "Wrote #{VerificationClaimResponse.count} responses to #{output_path}"
