# frozen_string_literal: true

# Export every fact-verification ("verify claim") exercise response as a CSV,
# one row per response, for comparison against the team's hand-checked answers
# in the Fall 2026 claim verification exercise spreadsheet.
#
#   bundle exec rails runner docs/analytics_scripts/fact_verification_curation/export_responses.rb
#   CAMPAIGN=fall_2026 OUT=/tmp/fv.csv bundle exec rails runner .../export_responses.rb
#
# Writes to OUT, or by default to ~/fv_responses_<date>.csv.
#
# Run this on production — the claim ids students answered against are
# production's `verification_claims.id`, which is the same id space the
# spreadsheet's "Claim ID" column uses (confirmed against the ids in
# config/claim_verification_rollout.yml's `excluded_claim_ids`). A local or
# staging database has its own harvest with its own ids and will not join.
#
# The answer columns are generated from ClaimVerification::ExerciseForm rather
# than listed here, so adding or retiring a question in
# config/claim_verification_exercise.yml changes the CSV without an edit here.
# Any answer key on record that the form no longer names (a response from before
# a question was dropped) gets a column of its own after the form's, so no answer
# is silently left out.
#
# Every row carries the full claim it answers, with every `verification_claims`
# column plus the wiki domain and source course slug, so the CSV stands on its
# own without a second claims export.
#
# Two columns exist to make the join checkable rather than assumed:
#
# - `claim_article_title` — compare against the spreadsheet's "Article name".
#   If those disagree for a claim id, the join is wrong and nothing downstream
#   of it means anything.
# - `currently_served` — whether RolloutList still offers this claim. Claims
#   curated out after the rollout began (165 ids are excluded, plus every other
#   pooled row for the same sentence) can still have responses from before the
#   exclusion, and those shouldn't be read as current behavior.

require 'csv'
require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"
require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"

form = ClaimVerification::ExerciseForm.new

course_ids = nil
if ENV['CAMPAIGN'].present?
  campaign = Campaign.find_by(slug: ENV['CAMPAIGN'])
  abort "No campaign with slug #{ENV['CAMPAIGN']}" if campaign.nil?
  course_ids = campaign.courses.pluck(:id)
end

responses = VerificationClaimResponse.includes(:course, :user,
                                               verification_claim: %i[wiki source_course])
responses = responses.where(course_id: course_ids) if course_ids
responses = responses.order(:created_at).to_a
abort 'No fact-verification responses to export.' if responses.empty?

# Authoritative rather than reimplemented: RolloutList also drops the other
# pooled rows for an excluded sentence, which a plain id check would miss.
claim_ids = responses.map(&:verification_claim_id).uniq
served = ClaimVerification::RolloutList.filter(VerificationClaim.where(id: claim_ids))
                                       .pluck(:id).to_set

answer_keys = form.answer_keys
answer_keys += responses.flat_map { |r| r.answers.to_h.keys.map(&:to_s) }.uniq - answer_keys

out = ENV['OUT'].presence || File.expand_path("~/fv_responses_#{Time.zone.today}.csv")

CSV.open(out, 'wb') do |csv|
  csv << ['response_id', 'submitted_at', 'updated_at', 'course_id', 'course_slug',
          'user_id', 'username', 'claim_id', 'claim_article_title', 'claim_sentence',
          'claim_source_url', 'claim_offline_source', 'currently_served',
          'claim_context', 'claim_cite_text', 'claim_archive_url', 'claim_ref_id',
          'claim_wiki', 'claim_article_id', 'claim_mw_rev_id', 'claim_mw_rev_timestamp',
          'claim_subject', 'claim_source_course_id', 'claim_source_course_slug',
          'claim_courses_users_id', 'claim_alert_id', 'claim_created_at'] + answer_keys

  responses.each do |r|
    claim = r.verification_claim
    answers = r.answers.to_h.stringify_keys
    csv << [r.id, r.created_at.iso8601, r.updated_at.iso8601, r.course_id, r.course.slug,
            r.user_id, r.user.username, r.verification_claim_id, claim.article_title,
            claim.sentence, claim.source_url, claim.offline_source,
            served.include?(r.verification_claim_id),
            claim.context, claim.cite_text, claim.archive_url, claim.ref_id,
            claim.wiki.domain, claim.article_id, claim.mw_rev_id,
            claim.mw_rev_timestamp&.iso8601, claim.subject, claim.source_course_id,
            claim.source_course&.slug, claim.courses_users_id, claim.alert_id,
            claim.created_at.iso8601] +
           answer_keys.map { |key| answers[key] }
  end
end

puts "Wrote #{responses.size} responses to #{out}"
puts "  students        #{responses.map(&:user_id).uniq.size}"
puts "  courses         #{responses.map(&:course_id).uniq.size}"
puts "  distinct claims #{claim_ids.size} (#{served.size} still served)"
puts "  claim id range  #{claim_ids.min}-#{claim_ids.max}"
extra_keys = answer_keys - form.answer_keys
puts "  answer keys not in the form: #{extra_keys.join(', ')}" if extra_keys.any?
