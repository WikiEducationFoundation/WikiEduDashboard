# frozen_string_literal: true

require_relative 'spec_helper'

# Captures the in-Canvas assignment drill-downs as they render TODAY: directly
# inside each assignment's tool iframe (no break-out button — the launch token
# authenticates the view; see LtiAnonymousLaunch). Covers all three assignment
# types the deep-link-first import creates:
#   - an exercise (Block) — instructor roster with inline sandbox preview, and
#     the student's own panel;
#   - "Wikipedia account" (setup) — the connection roster (Dashboard-side real
#     name + username, plus a pending never-connected member), and the
#     student's Connected confirmation;
#   - "Wikipedia trainings" (roll-up) — the instructor's linked module list
#     with per-module completion counts above the roster, and the student's
#     due-date table.
#
# Assignments are created the canonical way: the Modules-page bulk import
# (module_index_menu_modal), then a line-item sync binds the columns and a
# grade sync fills scores. The roster is padded with fabricated linked
# students (link_students) so it reads like a real class; a dedicated
# never-launching Canvas student provides the "Not connected" row.
#
#   bin/staging-feature-spec staging_specs/assignment_view_screenshots_spec.rb
describe 'Assignment drill-down screenshots', :staging do
  let(:required_env) do
    %w[
      CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID
      CANVAS_TEST_INSTRUCTOR_USER_ID
      CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
      CANVAS_TEST_STUDENT_USER_ID
      CANVAS_TEST_STUDENT_LOGIN CANVAS_TEST_STUDENT_PASSWORD
      WIKIPEDIA_TEST_INSTRUCTOR_USERNAME WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD
      WIKIPEDIA_TEST_STUDENT_USERNAME WIKIPEDIA_TEST_STUDENT_PASSWORD
      DASHBOARD_TEST_CAMPAIGN_SLUG
    ]
  end

  let(:run_id)             { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_course_name) { "Wiki Editing Demo (AV) #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo AV' }
  let(:dashboard_school)   { 'Demo School' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('assignment_view') }
  # Sage-provided test accounts, fabricated as extra roster rows so the drill-downs
  # read like a real class. 'Ragetest 37' has sandbox content at
  # User:<name>/Evaluate_an_Article (→ "Completed" + a rendered preview).
  #
  # These must exclude BOTH the real test student, who walks the launch and
  # contributes their own row, AND the instructor. 'Ragetest 9' was in this list
  # and is `WIKIPEDIA_TEST_INSTRUCTOR_USERNAME`: the instructor's launch already
  # creates a staff LtiContext for that Dashboard user, so fabricating a second,
  # student-role context for them gave one Wikipedia account two identities in one
  # course — which put the instructor in their own student roster in every
  # published gallery, and is the double-credit state
  # `index_lti_contexts_on_binding_and_user` now refuses outright. The index is
  # what surfaced this; before it, the insert simply succeeded.
  let(:gallery_students)   { ['Ragetest 37', 'Ragetest 14'] }
  let(:completed_students) { ['Ragetest 37'] }
  let(:preview_student)    { 'Ragetest_37' }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "AV-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_STUDENT_USER_ID'),
                           role: 'StudentEnrollment')
    dashboard_course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    provisioned[:timeline] = DashboardAdminClient.build_timeline(
      course_slug: dashboard_course['slug']
    )
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

  it 'captures every assignment type, instructor and student' do
    slug = provisioned[:dashboard_course_slug]
    canvas_id = provisioned[:canvas_course_id]
    timeline = provisioned[:timeline]
    exercise_label = timeline['exercise_line_item_label']

    prepare_course_state(slug:, canvas_id:, timeline:)
    assignments = find_imported_assignments(canvas_id, exercise_label, timeline)
    publish_assignments(canvas_id, assignments)
    sync_grades_for(slug)

    capture_instructor_views(canvas_id, assignments, exercise_label)
    capture_student_views(canvas_id, assignments)
  end

  # Imported assignments (and their module) arrive unpublished; students
  # can't open them until they're published, as an instructor would do.
  def publish_assignments(canvas_id, assignments)
    assignments.each_value do |assignment_id|
      next if assignment_id.nil? # a column this timeline doesn't carry

      canvas_api.publish_assignment(course_id: canvas_id, assignment_id:)
    end
    canvas_api.publish_all_modules(course_id: canvas_id)
  end

  # Bind deep-link-first, walk the real student through the launch (links +
  # enrolls them), fabricate the rest of the roster, import all assignments
  # via the Modules placement, then sync line items + grades.
  def prepare_course_state(slug:, canvas_id:, timeline:)
    # Deep-link-first is the default now; nothing to select at setup. The
    # import via the Modules placement (below) creates every column.
    bind_course_as_instructor(canvas_course_id: canvas_id, course_slug: slug)
    in_student_browser do
      student_walk_to_dashboard(canvas_course_id: canvas_id,
                                email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(page).to have_current_path(%r{/courses/}, url: true, wait: 60)
    end
    populate_roster(slug, timeline)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      import_assignments_via_modules(canvas_id)
    end
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
  end

  # Deliberately after publishing (see the example): a score posted at an
  # unpublished assignment appears to leave Canvas with no submission to attach the
  # launch URL to, which is what left the submission-placeholder shot with nothing
  # to open. Publishing first is also the order an instructor works in.
  def sync_grades_for(slug)
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])
  end

  def populate_roster(slug, timeline)
    linked = DashboardAdminClient.link_students(course_slug: slug, usernames: gallery_students)
    skip('gallery student accounts not found on staging') if linked.empty?

    completed_students.each do |username|
      DashboardAdminClient.mark_exercise_complete(
        course_slug: slug, username:, exercise_module_id: timeline['exercise_module_id']
      )
    end
    # The real student completes the training, so the trainings views show
    # genuine completion state (status, date, and the instructor count).
    DashboardAdminClient.mark_training_complete(
      username: student_username, training_module_id: timeline['training_module_id']
    )
    # And the exercise, because they are the only student who is also a Canvas
    # user: the submission placeholder shot needs a submission in Canvas, which
    # only exists once something has been reported for a real enrolled student.
    # The fabricated gallery students have no Canvas identity to submit as.
    DashboardAdminClient.mark_exercise_complete(
      course_slug: slug, username: student_username,
      exercise_module_id: timeline['exercise_module_id']
    )
    add_never_connected_student
    assign_gallery_articles(slug)
  end

  # One article each for the students the gallery shows, and a peer review of a
  # classmate's article for the real student — so the article panel and the
  # peer-review column report actual assignments rather than empty states.
  def assign_gallery_articles(slug)
    DashboardAdminClient.assign_articles(
      course_slug: slug,
      editing: { student_username => 'Chromatic aberration',
                 gallery_students.first => 'Selfie' },
      reviewing: { student_username => 'Selfie' }
    )
  end

  # A dedicated, never-launching Canvas student: roster-synced into a pending
  # (unlinked) context — the "Not connected" row the setup roster exists for.
  def add_never_connected_student
    student = canvas_api.find_or_create_user(unique_id: 'lti-unconnected-demo-student',
                                             name: 'Unconnected Demo Student')
    canvas_api.enroll_user(course_id: provisioned[:canvas_course_id],
                           user_id: student, role: 'StudentEnrollment')
    binding = DashboardAdminClient.find_binding(course_slug: provisioned[:dashboard_course_slug])
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
  end

  # The imported columns this flow drills into. `article_stage` is whichever
  # imported exercise carries the shared article panel (choosing the article, the
  # bibliography, the outline, continuing to improve) — the stage views that report
  # the student's article rather than a tick. `peer_review` exists only when the
  # course expects reviews, which the wizard timeline does.
  def find_imported_assignments(canvas_id, exercise_label, timeline)
    {
      exercise: canvas_api.find_assignment(course_id: canvas_id, name: exercise_label),
      setup: canvas_api.find_assignment(course_id: canvas_id, name: 'Wikipedia account'),
      trainings: canvas_api.find_assignment(course_id: canvas_id, name: 'Wikipedia trainings'),
      peer_review: peer_review_assignment(canvas_id, timeline),
      article_stage: find_article_stage_assignment(canvas_id)
    }.transform_values { |a| a&.fetch('id') }
  end

  # The column's own label, read off the gradables the timeline reported rather
  # than duplicating DeepLinkableGradables::PEER_REVIEW_LABEL (this process doesn't
  # boot Rails, so the constant isn't reachable).
  def peer_review_assignment(canvas_id, timeline)
    label = timeline['gradables'].to_a.find { |g| g['resource'] == 'PeerReview' }&.dig('label')
    label && canvas_api.find_assignment(course_id: canvas_id, name: label)
  end

  # Matched by label against the panel-bearing stages, in the order a student
  # meets them, so the shot is of the earliest one this timeline happens to carry.
  def find_article_stage_assignment(canvas_id)
    labels = canvas_api.list_assignments(course_id: canvas_id).to_a.map { |a| a['name'] }
    wanted = labels.find { |name| name =~ /choose|bibliograph|outline|keep improving/i }
    wanted && canvas_api.find_assignment(course_id: canvas_id, name: wanted)
  end

  def capture_instructor_views(canvas_id, assignments, exercise_label)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_assignment(canvas_id, assignments[:exercise])
      settle_in_iframe_view(exercise_label)
      capture('01-exercise-instructor-roster')
      expand_sandbox_preview
      capture('02-exercise-sandbox-preview')

      visit_assignment(canvas_id, assignments[:setup])
      settle_in_iframe_view('Wikipedia account')
      capture('03-setup-instructor-roster')

      visit_assignment(canvas_id, assignments[:trainings])
      settle_in_iframe_view('Wikipedia trainings')
      capture('04-trainings-instructor')

      capture_article_stage_instructor(canvas_id, assignments)
      capture_peer_review_instructor(canvas_id, assignments)
      capture_submission_view(canvas_id, assignments)
    end
  end

  # The stage views that report the article itself: which article each student took
  # on, and the state of every page of their work (bibliography, outline, draft)
  # plus what they've written live.
  def capture_article_stage_instructor(canvas_id, assignments)
    return warn '  [skip] no article-stage assignment imported' unless assignments[:article_stage]

    visit_assignment(canvas_id, assignments[:article_stage])
    # Gated on a page label inside the panel rather than its heading: the heading
    # is on the student's panel but not (yet) on the roster's, and this drives the
    # DEPLOYED app — a view change here only counts once it ships. "Draft sandbox"
    # is unique to the panel and always rendered for a course that uses sandboxes,
    # which the harness timeline does (`yes_sandboxes`).
    settle_in_iframe_view(t_lti('assignment_view.article_work.pages.draft'))
    capture('05-article-stage-instructor')
  end

  # Peer review reaches Canvas as its own column now — it has no exercise module,
  # so before that it couldn't be imported at all. The roster lists who is
  # reviewing what, not just a count.
  def capture_peer_review_instructor(canvas_id, assignments)
    return warn '  [skip] no peer-review column imported' unless assignments[:peer_review]

    visit_assignment(canvas_id, assignments[:peer_review])
    settle_in_iframe_view(t_lti('assignment_view.peer_review.reviews'))
    capture('06-peer-review-instructor')
  end

  # What an instructor gets when they open one student's submission — captured
  # from SpeedGrader, which is where an instructor actually grades, rather than by
  # visiting the stored submission URL directly.
  #
  # The direct visit is what the earlier version did, and it skipped: Canvas's
  # `external_tools/retrieve` wrapper reached without SpeedGrader's own context
  # doesn't land on a student-specific view. SpeedGrader does — verified in
  # `speed_grader_preview_diagnostic_spec` — and it is the honest shot anyway,
  # since it shows our view inside the grading UI the instructor is using.
  #
  # Skips with a reason rather than failing: this is one shot in a flow of twelve,
  # and SpeedGrader is a heavy SPA to wait on.
  def capture_submission_view(canvas_id, assignments)
    return warn '  [skip] no exercise column imported' unless assignments[:exercise]

    visit speed_grader_url(canvas_id, assignments[:exercise])
    unless speed_grader_shows_student_view?
      return warn '  [skip] SpeedGrader did not render the per-student view'
    end

    sleep 1
    capture('07-submission-view')
  end

  def speed_grader_url(canvas_id, assignment_id)
    "https://canvas.wikiedu.org/courses/#{canvas_id}/gradebook/speed_grader" \
      "?assignment_id=#{assignment_id}&student_id=#{ENV.fetch('CANVAS_TEST_STUDENT_USER_ID')}"
  end

  # SpeedGrader loads its submission iframe well after the page, so this waits on
  # the frame and then on our own copy inside it, reloading once in between.
  def speed_grader_shows_student_view?
    2.times do
      frame = first('iframe#speedgrader_iframe', wait: 25)
      if frame && within_frame(frame) { has_text?(t_lti('assignment_view.submission.details'),
                                                 wait: 20) }
        return true
      end

      page.refresh
    end
    false
  end

  def capture_student_views(canvas_id, assignments)
    in_student_browser do
      in_canvas do
        ensure_canvas_logged_in_as_student
        visit_assignment(canvas_id, assignments[:exercise])
        settle_in_iframe_view('Your sandbox')
        capture('08-exercise-student-panel')

        visit_assignment(canvas_id, assignments[:setup])
        settle_in_iframe_view('Connected')
        capture('09-setup-student-panel')

        visit_assignment(canvas_id, assignments[:trainings])
        settle_in_iframe_view('Due date')
        capture('10-trainings-student-table')

        if assignments[:article_stage]
          visit_assignment(canvas_id, assignments[:article_stage])
          settle_in_iframe_view(t_lti('assignment_view.article_work.pages.draft'))
          capture('11-article-stage-student')
        end

        if assignments[:peer_review]
          visit_assignment(canvas_id, assignments[:peer_review])
          settle_in_iframe_view(t_lti('assignment_view.peer_review.your_reviews'))
          capture('12-peer-review-student')
        end
      end
    end
  end

  def visit_assignment(canvas_id, assignment_id)
    expect(assignment_id).not_to be_nil
    visit "/courses/#{canvas_id}/assignments/#{assignment_id}"
    sleep 2
  end

  # Expand a completed student's "Show" toggle inside the tool iframe and wait
  # for the client-side fetch to render their sandbox content inline.
  def expand_sandbox_preview
    within_frame(first(canvas_assignment_iframe_locator, wait: 10)) do
      find(".lti-sandbox__toggle[data-sandbox-url*='#{preview_student}']").click
      expect(page).to have_css('.lti-sandbox__content--rendered', wait: 25)
      sleep 1
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
