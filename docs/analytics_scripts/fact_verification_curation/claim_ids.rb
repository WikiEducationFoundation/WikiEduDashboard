# frozen_string_literal: true

# Fact Verification exercise: durable ids for the rollout-list claims.
#
# The Fall 2026 curation spreadsheet identifies each claim by article name plus
# the "Claim X of N" position the exercise viewer shows for it. That position is
# nothing more than the claim's order among the highlighted spans in the
# annotated flagged revision, so it shifts as soon as a claim is removed from
# the pool. This reproduces the viewer's annotation for every revision in
# config/claim_verification_rollout.yml (the same AnnotateRevisionClaims call the
# annotated_article endpoint makes) and writes one row per highlighted claim —
# article, position, VerificationClaim id, ref id, sentence — so the spreadsheet
# can carry the id as its key. N is smaller than the pooled claim count because
# claims whose sentence can't be located in the rendered revision aren't
# highlighted; the per-article line printed for each revision is what to compare
# against the spreadsheet's row counts.
#
# Paste into a production Rails console. One parser API call per revision.
# Writes the CSV to FV_CLAIM_IDS_CSV (default: ~/fv_claim_ids.csv); merge it
# into the spreadsheet with claim_ids_merge.py.

require 'csv'
require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

output_path = ENV.fetch('FV_CLAIM_IDS_CSV', File.join(Dir.home, 'fv_claim_ids.csv'))

rows = [%w[article_title article_id mw_rev_id position claim_id ref_id sentence]]

ClaimVerification::RolloutList.pairs.each do |article_id, mw_rev_id|
  article = Article.find(article_id)
  html = AnnotateRevisionClaims.new(article:, mw_rev_id:).html
  # Document order — the order the viewer's prev/next steps through and numbers.
  markers = html ? Nokogiri::HTML.fragment(html).css('.cv-claim') : []
  markers.each_with_index do |marker, index|
    rows << [article.title, article_id, mw_rev_id, index + 1,
             marker['data-claim-id'], marker['data-ref-id'], marker['data-sentence']]
  end
  pooled = VerificationClaim.where(article_id:, mw_rev_id:).count
  puts "#{article.title}: #{markers.size} highlighted of #{pooled} pooled"
end

CSV.open(output_path, 'w') { |csv| rows.each { |row| csv << row } }
puts "Wrote #{rows.size - 1} claims to #{output_path}"
