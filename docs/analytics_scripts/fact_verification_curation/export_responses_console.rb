# Console-pasteable twin of export_responses.rb — the same CSV of student
# fact-verification responses, shaped for pasting into a production Rails
# console rather than running under `rails runner`.
#
# Paste the whole file, then:
#
#   fv_export                                  # writes ~/fv_responses_<date>.csv
#   fv_export(campaign: 'fall_2026')
#   fv_export(out: '/tmp/fv.csv')
#   fv_export(stdout: true)                    # print the CSV to copy off the box
#
# It returns the path it wrote, so the console echoes something short and
# useful rather than the whole file.
#
# Run this on PRODUCTION. The join key to the team's spreadsheet is the claim
# id, and that is production's `verification_claims.id` — the same id space
# `excluded_claim_ids` in config/claim_verification_rollout.yml names. A
# development database has its own harvest with its own ids and joins to
# nothing.
#
# `stdout: true` exists because getting a file off a production host is often
# more trouble than copying text out of the terminal. On a large result that is
# a lot of scrollback; write the file when you can.
#
# The column list is identical to export_responses.rb's, deliberately — both
# feed compare_responses.py, so the two must stay byte-identical in their
# header. The answer columns are generated from ClaimVerification::ExerciseForm,
# so a change to config/claim_verification_exercise.yml flows through to both
# without an edit to either.
#
# Console-specific differences, same as the other console twin: one method so
# the REPL buffers the whole paste, no `abort` (it would kill the session),
# and explicit `require_dependency` calls because lib/claim_verification/ is
# not autoloaded.

def fv_export(campaign: nil, out: nil, stdout: false)
  require 'csv'
  require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"
  require_dependency "#{Rails.root}/lib/claim_verification/rollout_list"
  form = ClaimVerification::ExerciseForm.new

  course_ids = nil
  if campaign
    found = Campaign.find_by(slug: campaign)
    return puts("No campaign with slug #{campaign}") if found.nil?
    course_ids = found.courses.pluck(:id)
  end

  rs = VerificationClaimResponse.includes(:course, :user, :verification_claim)
  rs = rs.where(course_id: course_ids) if course_ids
  rs = rs.order(:created_at).to_a
  return puts('No fact-verification responses to export.') if rs.empty?

  # Authoritative rather than reimplemented: RolloutList also drops the other
  # pooled rows for an excluded sentence, which a plain id check would miss.
  claim_ids = rs.map(&:verification_claim_id).uniq
  served = ClaimVerification::RolloutList.filter(VerificationClaim.where(id: claim_ids))
                                         .pluck(:id).to_set

  header = ['response_id', 'submitted_at', 'updated_at', 'course_id', 'course_slug',
            'user_id', 'username', 'claim_id', 'claim_article_title', 'claim_sentence',
            'claim_source_url', 'claim_offline_source', 'currently_served'] + form.answer_keys

  csv = CSV.generate do |c|
    c << header
    rs.each do |r|
      claim = r.verification_claim
      answers = r.answers.to_h.stringify_keys
      c << [r.id, r.created_at.iso8601, r.updated_at.iso8601, r.course_id, r.course.slug,
            r.user_id, r.user.username, r.verification_claim_id, claim.article_title,
            claim.sentence, claim.source_url, claim.offline_source,
            served.include?(r.verification_claim_id)] +
           form.answer_keys.map { |key| answers[key] }
    end
  end

  path = nil
  if stdout
    puts csv
  else
    path = out || File.expand_path("~/fv_responses_#{Time.zone.today}.csv")
    File.write(path, csv)
  end

  puts "#{rs.size} responses#{path ? " written to #{path}" : ''}"
  puts "  students        #{rs.map(&:user_id).uniq.size}"
  puts "  courses         #{rs.map(&:course_id).uniq.size}"
  puts "  distinct claims #{claim_ids.size} (#{served.size} still served)"
  puts "  claim id range  #{claim_ids.min}-#{claim_ids.max}"
  path
end
