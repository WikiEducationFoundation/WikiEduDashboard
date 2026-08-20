# frozen_string_literal: true

require_relative 'spec_helper'

# Measures the open question from the 2026-08-05 review of the Canvas integration:
# what does Canvas do with a second `Submitted`/`PendingManual` AGS score — no
# score value, carrying the submission extension with `new_submission: true` —
# that lands on a submission an instructor has already graded?
#
# Peer review is the column that raises it. `LtiPeerReviewProgress#signature`
# folds in both the fractional score and the "N of M peer reviews completed"
# comment, so it moves on every completed review; SyncLtiGrades therefore pushes
# again, and for an instructor-graded column every push claims a new submission.
# A course expecting three reviews produces three such pushes. Nothing on our
# side can answer what that does to a grade already entered in SpeedGrader —
# Canvas owns that — and this branch's history is three wrong designs for the
# submission extension, each corrected only by measurement.
#
# The sequence is the real one, end to end: two reviews assigned, the first
# completed and grade-synced, the instructor's grade entered on top of it, then
# the second completed and grade-synced.
#
# Unlike speed_grader_preview_diagnostic_spec.rb, which reports rather than
# asserts, this one asserts at the end. That spec was looking for a mechanism
# nobody knew, where a guess in an expectation would hide the gap. Here the
# requirement is known even though the behaviour wasn't: an instructor's grade
# must not be destroyed by the Dashboard's own later push. So the preconditions
# are asserted to keep a broken run from reporting nonsense, every observable is
# reported for the operator, and grade survival is asserted last.
#
# ANSWER, first measured 2026-08-05 against `2f18b6ffe`: the grade does not
# survive. A 0.75 entered between the two pushes came back nil with the column
# returned to `pending_review`, and `graded_at` left populated. The same run showed
# Canvas stores no submission comment at all for a no-score result (`comments=0`
# throughout), so the "N of M" progress those later pushes carried had never been
# reaching the gradebook. Both are written up in docs/canvas_integration_todos.md.
#
# So this is now a regression guard on SyncLtiGrades#already_reported?, which
# reports an instructor-graded column once per (column, student). It fails against
# any deploy predating that fix — including, until staging is redeployed, staging.
describe 'Peer review re-push against an instructor grade', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      CANVAS_TEST_STUDENT_USER_ID
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_STUDENT_USERNAME
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Staging PRRP #{run_id}" }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:student_canvas_id)  { ENV.fetch('CANVAS_TEST_STUDENT_USER_ID') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }

  # Two reviews, so the first completion is a partial score (0.5) and the second
  # a full one (1.0) — two pushes with different signatures, which is the shape
  # the finding describes. The titles only have to be distinct and stable.
  let(:review_titles) { ['Selenium', 'Molybdenum'] }
  let(:peer_review_label) { 'Wikipedia peer review' }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name,
                                             course_code: "PRRP-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: student_canvas_id, role: 'StudentEnrollment')
    dashboard_course = DashboardAdminClient.create_course(
      title: canvas_course_name, school: 'StagingTest', term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    DashboardAdminClient.build_timeline(course_slug: dashboard_course['slug'])
  end

  after do
    if provisioned[:canvas_course_id]
      DashboardAdminClient.delete_bindings_for(context_title: canvas_course_name)
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
    if provisioned[:dashboard_course_slug]
      DashboardAdminClient.delete_course(slug: provisioned[:dashboard_course_slug])
    end
  end

  it 'preserves the instructor grade when a later completed review re-pushes' do
    slug = provisioned[:dashboard_course_slug]
    prepare_course(slug)
    assignment = peer_review_assignment
    skip("no #{peer_review_label} column in Canvas") if assignment.nil?

    first = push_first_review(slug, assignment)
    graded = enter_instructor_grade(assignment)
    second = push_second_review(slug, assignment, graded)

    report_comparison(first, graded, second)

    # The question the review asked, in one line.
    expect(second['score'].to_f).to be_within(0.001).of(graded['score'].to_f)
    expect(second['workflow_state']).to eq('graded')
  end

  # --- phases ---------------------------------------------------------------

  def prepare_course(slug)
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id],
                              course_slug: slug)
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
    provisioned[:binding_id] = binding['id']
    linked = DashboardAdminClient.link_student_context(course_slug: slug,
                                                       username: student_username)
    skip('student dashboard account not found; run G7 once to create it') if linked == 'no_user'

    expect(DashboardAdminClient.set_peer_review_count(course_slug: slug, count: 2)).to eq(2)
    review_titles.each do |title|
      DashboardAdminClient.assign_articles(course_slug: slug,
                                            reviewing: { student_username => title })
    end
    # The column is only offered once reviews are expected, so importing has to
    # follow the count and the assignments.
    DashboardAdminClient.import_all_columns(course_slug: slug)
    count = DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    warn "\n== local line items after sync: #{count}"
  end

  def push_first_review(slug, assignment)
    DashboardAdminClient.mark_peer_review_complete(course_slug: slug,
                                                    username: student_username,
                                                    article_title: review_titles.first)
    progress = DashboardAdminClient.peer_review_progress(course_slug: slug,
                                                          username: student_username)
    provisioned[:first_signature] = progress['signature']
    warn "\n== progress after review 1: #{progress.slice('completed', 'expected', 'score',
                                                          'comment').inspect}"
    expect(progress['completed']).to eq(1)

    sync = DashboardAdminClient.run_grade_sync(binding_id: provisioned[:binding_id])
    warn "== grade sync 1: #{sync}"
    # Poll for the submission itself, not for the score comment. Measured
    # 2026-08-05: an instructor-graded push (PendingManual, no scoreGiven) creates
    # the submission but stores no submission_comment, so waiting on the comment
    # times out on a push that in fact landed.
    submission = eventually { current_submission(assignment) }
    report('push 1 — Dashboard reports one of two reviews done', submission)
    note_missing_comment(submission, '1 of 2 peer reviews completed')
    report_lti_state(slug) if submission.nil?

    # The scenario only exists if the first push leaves the submission for the
    # instructor to grade, which is the whole point of PendingManual with no score.
    expect(submission).not_to be_nil
    expect(submission['score']).to be_nil
    submission
  end

  def enter_instructor_grade(assignment)
    # A value neither push could produce: both send no score at all, so any grade
    # is distinguishable, and a fraction of the column's own maximum is the shape
    # an instructor would actually enter.
    points = assignment['points_possible'].to_f
    grade = points.positive? ? (points * 0.75).round(2) : 0.75
    canvas_api.grade_submission(course_id: provisioned[:canvas_course_id],
                               assignment_id: assignment['id'],
                               user_id: student_canvas_id, grade:)
    submission = eventually { graded_submission(assignment) }
    report("instructor grades it #{grade}", submission)

    expect(submission).not_to be_nil
    expect(submission['score'].to_f).to be_within(0.001).of(grade.to_f)
    submission
  end

  def push_second_review(slug, assignment, graded)
    DashboardAdminClient.mark_peer_review_complete(course_slug: slug,
                                                    username: student_username,
                                                    article_title: review_titles.last)
    progress = DashboardAdminClient.peer_review_progress(course_slug: slug,
                                                          username: student_username)
    warn "\n== progress after review 2: #{progress.slice('completed', 'expected', 'score',
                                                          'comment').inspect}"
    # Push 2 only happens because the signature moved. Assert the mechanism the
    # finding names, so a run where nothing was pushed can't read as a pass.
    expect(progress['completed']).to eq(2)
    expect(progress['signature']).not_to eq(provisioned[:first_signature])

    sync = DashboardAdminClient.run_grade_sync(binding_id: provisioned[:binding_id])
    warn "== grade sync 2: #{sync}"
    # Wait on the attempt counter, not on the grade: whether the grade changes is
    # the thing being measured, so polling for that would beg the question. Push 2
    # claims `new_submission: true`, so a stored new attempt is the signal it
    # landed — and if Canvas refuses one on a graded submission, the fallback
    # reports whatever state it did leave.
    submission = await_new_attempt(assignment, after: graded['attempt']) ||
                 current_submission(assignment)
    report('push 2 — second review completed, pushed over the instructor grade',
           submission)
    note_missing_comment(submission, '2 of 2 peer reviews completed')
    submission
  end

  # --- Canvas reads ---------------------------------------------------------

  def peer_review_assignment
    eventually do
      canvas_api.find_assignment(course_id: provisioned[:canvas_course_id],
                                 name: peer_review_label)
    end
  end

  def current_submission(assignment)
    canvas_api.submission(course_id: provisioned[:canvas_course_id],
                          assignment_id: assignment['id'],
                          user_id: student_canvas_id)
  end

  def graded_submission(assignment)
    sub = current_submission(assignment)
    sub if sub && sub['workflow_state'] == 'graded' && !sub['score'].nil?
  end

  # Neither of these rescues: a Canvas API error is the answer to why a push looks
  # missing, and swallowing it into a nil reads as "Canvas stored nothing" instead.
  def await_new_attempt(assignment, after:)
    eventually do
      sub = current_submission(assignment)
      sub if sub && sub['attempt'].to_i > after.to_i
    end
  end

  # The score comment is sent on every push, so its absence is worth recording
  # wherever it happens — but it is not what this spec measures, and failing on it
  # would stop the run before it reaches the grade.
  def note_missing_comment(submission, text)
    return if comment_text(submission).include?(text)

    warn "   NOTE: no submission_comment carrying #{text.inspect} " \
         "(#{Array(submission&.[]('submission_comments')).size} comments present)"
  end

  # --- reporting ------------------------------------------------------------

  def report(label, submission)
    warn "\n== #{label}"
    return warn '   no submission' if submission.nil?

    warn "   score=#{submission['score'].inspect} grade=#{submission['grade'].inspect} " \
         "state=#{submission['workflow_state'].inspect}"
    warn "   attempt=#{submission['attempt'].inspect} " \
         "type=#{submission['submission_type'].inspect} " \
         "graded_at=#{submission['graded_at'].inspect}"
    warn "   url=#{submission['url'].to_s[0, 160].inspect}"
    warn "   preview=#{submission['preview_url'].to_s[0, 120].inspect}"
    comments = Array(submission['submission_comments'])
    warn "   comments=#{comments.size}"
    comments.each_with_index do |comment, i|
      warn "     [#{i}] #{comment['comment'].to_s.gsub(/\s+/, ' ')[0, 140]}"
    end
  end

  # Which side to look at when a push doesn't show up in Canvas.
  def report_lti_state(slug)
    state = DashboardAdminClient.lti_state(course_slug: slug)
    warn "\n== LTI state (push did not land as expected)"
    warn "   last_grade_sync_at=#{state['last_grade_sync_at'].inspect}"
    warn "   last_grade_sync_error=#{state['last_grade_sync_error'].inspect}"
    warn "   contexts=#{state['contexts'].inspect}"
    state['line_items'].each do |item|
      warn "   [#{item['type']}#{item['gradable_id'] ? ":#{item['gradable_id']}" : ''}] " \
           "label=#{item['label'].inspect} archived=#{item['archived']} " \
           "canvas_assignment_id=#{item['canvas_assignment_id'].inspect}"
      warn "       lineitem_id=…#{item['lineitem_id']}"
      warn "       signatures=#{item['signatures'].inspect}"
    end
  end

  # The three facts the review asked for, side by side, so the answer doesn't
  # have to be reconstructed from the per-phase dumps above.
  def report_comparison(first, graded, second)
    warn "\n== ANSWER"
    warn "   grade before push 2: #{graded['score'].inspect} (#{graded['workflow_state']})"
    warn "   grade after  push 2: #{second['score'].inspect} (#{second['workflow_state']})"
    warn "   grade survived: #{second['score'].to_f == graded['score'].to_f}"
    warn "   comments: #{Array(first['submission_comments']).size} after push 1, " \
         "#{Array(graded['submission_comments']).size} after grading, " \
         "#{Array(second['submission_comments']).size} after push 2"
    warn "   attempts: #{first['attempt'].inspect} → #{graded['attempt'].inspect} → " \
         "#{second['attempt'].inspect}"
    warn "   submission url after push 2: #{second['url'].to_s[0, 160].inspect}"
  end

  def comment_text(submission)
    Array(submission&.[]('submission_comments')).map { |c| c['comment'].to_s }.join("\n")
  end
end
