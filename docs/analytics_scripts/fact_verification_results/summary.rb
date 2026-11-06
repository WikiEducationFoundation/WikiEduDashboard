# frozen_string_literal: true

# Summarize how the fact-verification ("verify claim") exercise is going:
# take-up, how students are answering each question, and which claims they
# picked.
#
#   bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
#   CAMPAIGN=fall_2026 bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
#   NOTES=1 bundle exec rails runner docs/analytics_scripts/fact_verification_results/summary.rb
#
# CAMPAIGN scopes to one campaign's courses; NOTES also dumps the free-text
# answers, which are the qualitative half of the picture and don't summarize.
#
# The questions are read from ClaimVerification::ExerciseForm rather than listed
# here, so editing config/claim_verification_exercise.yml — adding a step,
# retiring an option — changes what this reports with no edit to this file.
#
# Two things it is deliberately careful about, because either would otherwise
# give a wrong read of the exercise:
#
# 1. Denominators. Most questions are gated — `verdict` is only asked of
#    students who got hold of the source — so a percentage over all responses
#    would understate every answer to a gated question. Each tally runs over the
#    responses that were actually *asked* that question, per ExerciseForm's own
#    gating rules.
# 2. Retired options. Answers like `mostly_supports` are still on older records
#    but aren't offered any more. They're reported under a separate heading so
#    they don't read as answers students can still give.

require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"

FORM = ClaimVerification::ExerciseForm.new
SHOW_NOTES = ENV['NOTES'].present?

campaign = nil
if ENV['CAMPAIGN'].present?
  campaign = Campaign.find_by(slug: ENV['CAMPAIGN'])
  abort "No campaign with slug #{ENV['CAMPAIGN']}" if campaign.nil?
end
course_ids = campaign&.courses&.pluck(:id)

responses = VerificationClaimResponse.includes(:course, :user, verification_claim: :article)
responses = responses.where(course_id: course_ids) if course_ids
responses = responses.order(:created_at).to_a

if responses.empty?
  puts "No fact-verification responses#{campaign ? " in #{campaign.slug}" : ''} yet."
  exit
end

# Answers are stored with string keys; the gating rules read them that way.
ANSWERS = responses.to_h { |r| [r.id, r.answers.to_h.stringify_keys] }.freeze

# Which questions each response was actually asked, by the path the student
# took. Computed once per response rather than once per (response, question).
ASKED = responses.to_h { |r|
  [r.id, FORM.applicable_questions(ANSWERS[r.id]).map(&:id).to_set]
}.freeze

def pct(count, total)
  return '    —' if total.zero?
  format('%5.1f%%', 100.0 * count / total)
end

def heading(text)
  puts
  puts text
  puts '-' * text.length
end

def asked_for(responses, question_id)
  responses.select { |r| ASKED[r.id].include?(question_id) }
end

def tally(responses, question_id)
  responses.group_by { |r| ANSWERS[r.id][question_id] }.transform_values(&:size)
end

# --- Overall -----------------------------------------------------------------

heading("Fact-verification exercise#{campaign ? " — #{campaign.slug}" : ''}")
puts "  responses         #{responses.size}"
puts "  students          #{responses.map(&:user_id).uniq.size}"
puts "  courses           #{responses.map(&:course_id).uniq.size}"
puts "  distinct claims   #{responses.map(&:verification_claim_id).uniq.size}"
puts "  distinct articles #{responses.map { |r| r.verification_claim.article_title }.uniq.size}"
puts "  submitted         #{responses.first.created_at.to_date} to #{responses.last.created_at.to_date}"

# --- Take-up -----------------------------------------------------------------
#
# The assignment is a re-pointable cursor — one row per student per course,
# repointed when they choose a different claim — so an assignment with no
# response for *that* claim means the student is holding a claim they haven't
# submitted on. It does not mean they've never submitted anything, which is why
# both numbers are reported.

assignments = VerificationClaimAssignment.all
assignments = assignments.where(course_id: course_ids) if course_ids
assignments = assignments.to_a
responded = responses.map { |r| [r.user_id, r.course_id, r.verification_claim_id] }.to_set
any_response = responses.map { |r| [r.user_id, r.course_id] }.to_set

heading('Take-up')
puts "  students holding a claim        #{assignments.size}"
held_unsubmitted = assignments.reject do |a|
  responded.include?([a.user_id, a.course_id, a.verification_claim_id])
end
puts "  current claim not submitted     #{held_unsubmitted.size} " \
     "(#{pct(held_unsubmitted.size, assignments.size).strip} of holders)"
never_submitted = assignments.reject { |a| any_response.include?([a.user_id, a.course_id]) }
puts "  never submitted anything        #{never_submitted.size} " \
     "(#{pct(never_submitted.size, assignments.size).strip} of holders)"

# --- Choice questions --------------------------------------------------------

FORM.questions.select(&:choice?).each do |question|
  asked = asked_for(responses, question.id)
  counts = tally(asked, question.id)

  heading("#{question.id}  (asked of #{asked.size})")
  question.option_labels.each do |option|
    count = counts.fetch(option[:value], 0)
    puts format('  %-22s %5d  %s   %s',
                option[:value], count, pct(count, asked.size), option[:label])
  end

  retired = question.retired_option_labels.select { |o| counts.key?(o[:value]) }
  unless retired.empty?
    puts '  no longer offered:'
    retired.each do |option|
      count = counts.fetch(option[:value], 0)
      puts format('  %-22s %5d  %s   %s',
                  option[:value], count, pct(count, asked.size), option[:label])
    end
  end

  unanswered = counts.fetch(nil, 0)
  next unless unanswered.positive?
  puts format('  %-22s %5d  %s', '(no answer)', unanswered, pct(unanswered, asked.size))
  # A *required* question with no answer doesn't mean students skipped it — the
  # form blocks submission until it's answered. It means the response predates
  # the question being added to the exercise. The date says which it is: an old
  # last-seen date is that history, a recent one is a real problem.
  next unless question.required
  stale = asked.select { |r| ANSWERS[r.id][question.id].blank? }.map(&:created_at).max
  puts "    required, so these predate the question — latest #{stale.to_date}"
end

# --- Free text ---------------------------------------------------------------

heading('Free-text answers')
FORM.questions.reject { |q| q.choice? || !q.answerable? }.each do |question|
  asked = asked_for(responses, question.id)
  filled = asked.reject { |r| ANSWERS[r.id][question.id].blank? }
  puts format('  %-26s %4d of %4d asked  %s',
              question.id, filled.size, asked.size, pct(filled.size, asked.size))
end

if SHOW_NOTES
  FORM.questions.reject { |q| q.choice? || !q.answerable? }.each do |question|
    filled = asked_for(responses, question.id)
             .reject { |r| ANSWERS[r.id][question.id].blank? }
    next if filled.empty?
    heading(question.id)
    filled.each do |r|
      puts "  [#{r.course.slug}] #{r.verification_claim.article_title}"
      puts "    #{ANSWERS[r.id][question.id].gsub("\n", "\n    ")}"
    end
  end
end

# --- Where students are working ----------------------------------------------

heading('Most-picked claims')
responses.group_by(&:verification_claim_id)
         .sort_by { |_id, rs| -rs.size }
         .first(15)
         .each do |_id, rs|
  claim = rs.first.verification_claim
  puts format('  %4d  %-44s %s', rs.size, claim.article_title.to_s.truncate(44),
              claim.sentence.to_s.truncate(60))
end

heading('By course')
responses.group_by(&:course_id).sort_by { |_id, rs| -rs.size }.each do |_id, rs|
  puts format('  %-52s %4d responses  %3d students',
              rs.first.course.slug.truncate(52), rs.size, rs.map(&:user_id).uniq.size)
end
puts
