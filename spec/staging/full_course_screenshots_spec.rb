# frozen_string_literal: true

require_relative 'spec_helper'

# Full-course instructor gallery: a bound course with a realistic multi-week
# timeline (the standard article-writing milestones), one linked student with
# MIXED progress (early stages done, later ones not), showing how the whole
# course looks to the instructor — the Canvas gradebook with every milestone as
# a column (Wikipedia account + Wikipedia trainings + one per exercise), some
# complete, some not.
#
# The per-assignment drill-down (instructor roster + inline sandbox preview) is
# captured separately in assignment_view_screenshots_spec, which shows it with a
# full multi-student roster. Here the sandbox milestones are still deep-linked
# authentically so they're launchable; the rest are created fast via AGS
# (upsert_exercise_columns) as a stand-in for the instructor deep-linking each —
# the gradebook is identical either way.
#
#   bin/staging-feature-spec spec/staging/full_course_screenshots_spec.rb
describe 'Full course — instructor gallery', :staging do
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
  let(:canvas_course_name) { "Wiki Editing Full Course #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Full Course' }
  let(:dashboard_school)   { 'Demo School' }
  let(:student_username)   { ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME') }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('full_course') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "FC-#{run_id}")
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
    provisioned[:timeline] =
      DashboardAdminClient.build_full_timeline(course_slug: dashboard_course['slug'])
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

  it 'captures the full-course gradebook with every milestone column' do
    slug = provisioned[:dashboard_course_slug]
    canvas_id = provisioned[:canvas_course_id]
    blocks = provisioned[:timeline]['blocks']
    skip('no exercise milestones in the staging library') if blocks.empty?

    result = prepare_full_course(slug:, canvas_id:, blocks:)
    skip('student dashboard account not found; run g7 once') if result == :no_student

    # The per-assignment drill-down (roster + inline sandbox preview) is captured
    # in assignment_view_screenshots_spec; here we only want the gradebook overview.
    capture_full_gradebook(canvas_id)
  end

  # Bind in 'standard' mode (auto-creates every milestone column, launchable),
  # link the student, mark ~half the milestones complete for a realistic mix,
  # then sync line items + grade. Returns nil, or :no_student.
  def prepare_full_course(slug:, canvas_id:, blocks:)
    bind_course_as_instructor(canvas_course_id: canvas_id, course_slug: slug,
                              granularity: 'standard')
    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])
    linked = DashboardAdminClient.link_student_context(course_slug: slug,
                                                       username: student_username)
    return :no_student if linked == 'no_user'

    mark_mixed_progress(slug, blocks)
    DashboardAdminClient.run_line_item_sync(binding_id: binding['id'])
    DashboardAdminClient.run_grade_sync(binding_id: binding['id'])
    nil
  end

  # Complete the first half of the milestones for the student (early stages done,
  # later ones not), so the gradebook shows a realistic mix of marked/unmarked.
  def mark_mixed_progress(slug, blocks)
    blocks.first((blocks.size / 2.0).ceil).each do |b|
      DashboardAdminClient.mark_exercise_complete(
        course_slug: slug, username: student_username, exercise_module_id: b['module_id']
      )
    end
  end

  def capture_full_gradebook(canvas_id)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      # Wide enough to fit every milestone column (setup + trainings + exercises).
      page.current_window.resize_to(2200, 1000)
      visit "/courses/#{canvas_id}/gradebook"
      expect(page).to have_content('Wikipedia trainings', wait: 40)
      sleep 2 # let the grid finish painting the scores
      capture('f01-full-course-gradebook')
    end
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
