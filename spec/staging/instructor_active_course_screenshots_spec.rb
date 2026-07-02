# frozen_string_literal: true

require_relative 'spec_helper'

# Captures what a course INSTRUCTOR sees on their bound Dashboard course as the
# class comes online — the before/after of the roster filling in as a student
# launches from Canvas and links their account. Output goes to the harvest run
# dir (`tmp/canvas-ux-screenshots/active_course/`, override with
# CANVAS_SHOTS_DIR); `bin/harvest-canvas-screenshots` collects it into the
# review gallery.
#
#   bin/staging-feature-spec spec/staging/instructor_active_course_screenshots_spec.rb
#
# The instructor binds the course (arriving via the Canvas launch), then:
#   - BEFORE any student has launched: the instructor's course home shows a
#     student-editor count of 0 and the roster (which lists students only) is empty.
#   - A student walks their own launch + Wikipedia OAuth, linking their account;
#     a roster sync then enrolls the now-linked student into the Dashboard course.
#   - AFTER: the course home's student-editor count is 1 and the student appears
#     in the roster.
#
# A student's own launch links their LTI context (link_lti_user sets user_id); a
# Canvas enrollment alone stays "deferred" (see LtiMemberLinker). Enrollment into
# the Dashboard course/roster (JoinCourse) — which is what the home count and the
# roster reflect — happens when the roster sync processes that linked context,
# which is why the after shots run one first.
#
# Two browser personas (instructor default profile + student profile); both must
# be bootstrapped once — see docs/staging_feature_specs.md.
describe 'Instructor active-course screenshots', :staging do
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
  let(:canvas_course_name) { "Wiki Editing Demo Course #{run_id}" }
  let(:dashboard_title)    { 'Wiki Editing Demo' }
  let(:dashboard_school)   { 'StagingTest' }
  let(:canvas_api)         { CanvasApiClient.new }
  let(:provisioned)        { @provisioned ||= {} }
  let(:screenshot_dir)     { canvas_shots_dir('active_course') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    canvas_course = canvas_api.create_course(name: canvas_course_name, course_code: "AC-#{run_id}")
    provisioned[:canvas_course_id] = canvas_course['id']
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')
    canvas_api.enroll_user(course_id: canvas_course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_STUDENT_USER_ID'),
                           role: 'StudentEnrollment')
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

  it 'captures the instructor roster before and after a student signs in' do
    slug = provision_dashboard_course
    bind_course_as_instructor(canvas_course_id: provisioned[:canvas_course_id], course_slug: slug)

    capture_instructor_course_state(slug, home: 'i01-before-course-home',
                                          roster: 'i02-before-students-roster')

    in_student_browser do
      student_walk_to_dashboard(canvas_course_id: provisioned[:canvas_course_id],
                                email: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'))
      expect(page).to have_current_path(%r{/courses/StagingTest/}, url: true, wait: 60)
    end

    binding = DashboardAdminClient.find_binding(course_slug: slug)
    DashboardAdminClient.run_roster_sync(binding_id: binding['id'])

    student = ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME')
    capture_instructor_course_state(slug, home: 'i03-after-course-home',
                                          roster: 'i04-after-students-roster',
                                          expect_student: student)
  end

  # Create + approve a Dashboard course owned by the test instructor.
  def provision_dashboard_course
    course = DashboardAdminClient.create_course(
      title: dashboard_title, school: dashboard_school, term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = course['slug']
    DashboardAdminClient.approve_course(slug: course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    course['slug']
  end

  # Screenshot the instructor's course home (overview stats, incl. the
  # student-editor count) and the students roster. `await_lms_panel` doubles as a
  # load gate that the bound course + its integration data have rendered. When
  # `expect_student` is given, wait for that username in the roster first, so the
  # "after" shots are captured only once the sync has landed.
  def capture_instructor_course_state(slug, home:, roster:, expect_student: nil)
    in_dashboard { visit "/courses/#{slug}/home" }
    await_lms_panel
    capture(home)
    in_dashboard { visit "/courses/#{slug}/students/overview" }
    expect(page).to have_css('.list__wrapper', wait: 20)
    expect(page).to have_content(expect_student, wait: 30) if expect_student
    capture(roster)
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
