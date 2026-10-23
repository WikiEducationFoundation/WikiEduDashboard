# Console-pasteable twin of summary.rb — same summary of how
# the fact-verification ("verify claim") exercise is going, shaped for pasting
# straight into a Rails console rather than running under `rails runner`.
#
# Paste the whole file, then:
#
#   ActiveRecord::Base.logger = nil   # else SQL logging interleaves with output
#   fv_summary
#   fv_summary(campaign: 'fall_2026')
#   fv_summary(notes: true)           # also dumps the free-text answers
#   rs = fv_summary                   # returns the response records to poke at
#
# Four things differ from the runner version, each forced by the console:
#
# 1. It's one method, not a script. The console buffers the whole paste until
#    the final `end`, so nothing evaluates early — which matters because of the
#    leading-dot continuation lines a REPL would otherwise treat as complete
#    expressions. No top-level constants either, so re-pasting after an edit
#    redefines the method silently instead of warning.
# 2. No `exit`/`abort` — those would kill the session. Both early exits return.
# 3. An explicit `require_dependency`: lib/claim_verification/ isn't autoloaded,
#    so a bare console raises `uninitialized constant ClaimVerification`.
# 4. It returns the loaded responses, for drilling in after the summary prints.
#
# The analysis itself is identical to the runner version, including the three
# things that are easy to get wrong by hand: gated denominators, retired options
# reported separately, and a required question with no answer read as predating
# the question rather than as a student skipping it. Keep the two in step — if
# you change the analysis in one, change it in the other.

def fv_summary(campaign: nil, notes: false)
  # lib/claim_verification/ isn't autoloaded, so the console needs this.
  require_dependency "#{Rails.root}/lib/claim_verification/exercise_form"
  form = ClaimVerification::ExerciseForm.new

  course_ids = nil
  if campaign
    found = Campaign.find_by(slug: campaign)
    return puts("No campaign with slug #{campaign}") if found.nil?
    course_ids = found.courses.pluck(:id)
  end

  rs = VerificationClaimResponse.includes(:course, :user, verification_claim: :article)
  rs = rs.where(course_id: course_ids) if course_ids
  rs = rs.order(:created_at).to_a
  return puts('No fact-verification responses yet.') if rs.empty?

  # Answers are stored with string keys; the gating rules read them that way.
  answers = rs.to_h { |r| [r.id, r.answers.to_h.stringify_keys] }
  # Which questions each response was actually asked, by the path the student
  # took. Once per response, not once per (response, question).
  asked_ids = rs.to_h { |r| [r.id, form.applicable_questions(answers[r.id]).map(&:id).to_set] }

  pct = ->(n, total) { total.zero? ? '    —' : format('%5.1f%%', 100.0 * n / total) }
  head = ->(text) { puts; puts text; puts('-' * text.length) }
  asked_for = ->(qid) { rs.select { |r| asked_ids[r.id].include?(qid) } }
  row = ->(label, n, total, note) { puts format('  %-22s %5d  %s   %s', label, n, pct[n, total], note) }

  head["Fact-verification exercise#{campaign ? " — #{campaign}" : ''}"]
  puts "  responses         #{rs.size}"
  puts "  students          #{rs.map(&:user_id).uniq.size}"
  puts "  courses           #{rs.map(&:course_id).uniq.size}"
  puts "  distinct claims   #{rs.map(&:verification_claim_id).uniq.size}"
  puts "  distinct articles #{rs.map { |r| r.verification_claim.article_title }.uniq.size}"
  puts "  submitted         #{rs.first.created_at.to_date} to #{rs.last.created_at.to_date}"

  # The assignment is a re-pointable cursor — one row per student per course,
  # repointed when they choose a different claim — so "current claim not
  # submitted" means they're holding a claim they haven't finished, NOT that
  # they've never submitted anything. Both are reported.
  assigns = VerificationClaimAssignment.all
  assigns = assigns.where(course_id: course_ids) if course_ids
  assigns = assigns.to_a
  done = rs.map { |r| [r.user_id, r.course_id, r.verification_claim_id] }.to_set
  ever = rs.map { |r| [r.user_id, r.course_id] }.to_set
  held = assigns.reject { |a| done.include?([a.user_id, a.course_id, a.verification_claim_id]) }
  never = assigns.reject { |a| ever.include?([a.user_id, a.course_id]) }

  head['Take-up']
  puts "  students holding a claim        #{assigns.size}"
  puts "  current claim not submitted     #{held.size}  #{pct[held.size, assigns.size]}"
  puts "  never submitted anything        #{never.size}  #{pct[never.size, assigns.size]}"

  # Denominators follow the form's own gating: `verdict` is only asked of
  # students who got the source, so it's tallied over the responses that
  # reached it, not over all responses.
  form.questions.select(&:choice?).each do |q|
    asked = asked_for[q.id]
    counts = asked.group_by { |r| answers[r.id][q.id] }.transform_values(&:size)

    head["#{q.id}  (asked of #{asked.size})"]
    q.option_labels.each { |o| row[o[:value], counts.fetch(o[:value], 0), asked.size, o[:label]] }

    retired = q.retired_option_labels.select { |o| counts.key?(o[:value]) }
    unless retired.empty?
      puts '  no longer offered:'
      retired.each { |o| row[o[:value], counts.fetch(o[:value], 0), asked.size, o[:label]] }
    end

    blank = counts.fetch(nil, 0)
    next unless blank.positive?
    puts format('  %-22s %5d  %s', '(no answer)', blank, pct[blank, asked.size])
    # A *required* question with no answer doesn't mean students skipped it —
    # the form blocks submission until it's answered. It means the response
    # predates the question being added. An old date is that history; a recent
    # one is a real problem.
    next unless q.required
    last = asked.select { |r| answers[r.id][q.id].blank? }.map(&:created_at).max
    puts "    required, so these predate the question — latest #{last.to_date}"
  end

  texts = form.questions.reject { |q| q.choice? || !q.answerable? }
  head['Free-text answers']
  texts.each do |q|
    asked = asked_for[q.id]
    filled = asked.reject { |r| answers[r.id][q.id].blank? }
    puts format('  %-26s %4d of %4d asked  %s', q.id, filled.size, asked.size,
                pct[filled.size, asked.size])
  end

  if notes
    texts.each do |q|
      filled = asked_for[q.id].reject { |r| answers[r.id][q.id].blank? }
      next if filled.empty?
      head[q.id]
      filled.each do |r|
        puts "  [#{r.course.slug}] #{r.verification_claim.article_title}"
        puts "    #{answers[r.id][q.id].gsub("\n", "\n    ")}"
      end
    end
  end

  head['Most-picked claims']
  top = rs.group_by(&:verification_claim_id).sort_by { |_id, g| -g.size }.first(15)
  top.each do |_id, g|
    c = g.first.verification_claim
    puts format('  %4d  %-44s %s', g.size, c.article_title.to_s.truncate(44),
                c.sentence.to_s.truncate(60))
  end

  head['By course']
  rs.group_by(&:course_id).sort_by { |_id, g| -g.size }.each do |_id, g|
    puts format('  %-52s %4d responses  %3d students', g.first.course.slug.truncate(52),
                g.size, g.map(&:user_id).uniq.size)
  end

  rs
end
