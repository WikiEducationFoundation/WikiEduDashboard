# frozen_string_literal: true

require 'rails_helper'

describe LtiLaunchController, type: :request do
  let(:user) { create(:user) }
  let(:ltiaas_domain) { 'tenant.ltiaas.com' }
  let(:idtoken_url) { "https://#{ltiaas_domain}/api/idtoken" }
  let(:idtoken) { idtoken_for(role) }
  let(:role) { 'Instructor' }

  def idtoken_for(role)
    {
      'user' => { 'id' => 'lti-user-1', 'name' => 'Jane', 'email' => 'jane@example.edu',
                  'roles' => ["http://purl.imsglobal.org/vocab/lis/v2/membership##{role}"] },
      'platform' => { 'id' => 'platform-x', 'productFamilyCode' => 'canvas' },
      'launch' => {
        'context' => { 'id' => 'canvas-77', 'title' => 'WRIT 2010' },
        'resourceLink' => { 'id' => 'rl-99' }
      },
      'services' => { 'namesAndRoles' => {}, 'assignmentAndGrades' => {} }
    }
  end

  # Raw JWT claims (GET /api/idtoken?raw=true) — carries the deep-linking
  # settings the processed idtoken omits. Empty = single-item placements.
  let(:raw_idtoken) { {} }

  # Pre-existing Dashboard enrollment, for the specs whose subject is what a
  # student's launch *renders* rather than what it enrolls.
  def enroll_student(student = user)
    CoursesUsers.create!(user: student, course:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  # Connecting a Dashboard account to an LMS identity is its own approved step
  # now (LtiLaunchController#connect_identity), not something a launch does on
  # the way past. Examples whose subject is what a launch *renders* start from an
  # already-connected account; the approval itself has its own describe block.
  def approve_identity_link(dashboard_user = user, lti_user_id: 'lti-user-1')
    binding = LtiCourseBinding.find_or_create_by!(lms_id: 'platform-x',
                                                 lms_context_id: 'canvas-77') do |b|
      b.lms_family = 'canvas'
      b.lms_resource_link_id = 'rl-99'
    end
    context = LtiContext.find_or_initialize_by(user_lti_id: lti_user_id,
                                              lti_course_binding_id: binding.id)
    context.update!(user: dashboard_user, lms_id: 'platform-x', linked_at: Time.current,
                    roles: ["http://purl.imsglobal.org/vocab/lis/v2/membership##{role}"])
    context
  end

  # Find-or-create so a fixture binding and a pre-approved link can be set up in
  # either order — the link needs a binding, and RSpec runs `let!` hooks in
  # declaration order.
  def lti_binding_for(course)
    LtiCourseBinding.find_or_create_by!(lms_id: 'platform-x',
                                        lms_context_id: 'canvas-77') do |b|
      b.lms_family = 'canvas'
      b.lms_resource_link_id = 'rl-99'
    end.tap { |b| b.update!(course:) }
  end

  before do
    ENV['LTIAAS_DOMAIN'] = ltiaas_domain
    ENV['LTIAAS_API_KEY'] = 'k'
    allow(Features).to receive(:canvas_integration?).and_return(true)
    stub_request(:get, idtoken_url)
      .to_return(status: 200, body: idtoken.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    stub_request(:get, idtoken_url)
      .with(query: { 'raw' => 'true' })
      .to_return(status: 200, body: raw_idtoken.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    allow(LtiRosterSyncWorker).to receive(:perform_async)
    allow(LtiLineItemSyncWorker).to receive(:perform_async)
  end

  describe 'GET /lti' do
    context 'when ltik is missing' do
      it 'redirects to the login error page' do
        get '/lti'
        expect(response).to redirect_to('/errors/login_error')
      end
    end

    context 'when not signed in' do
      it 'renders an iframe-friendly landing page that escapes to top-level' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Open the Wiki Education Dashboard')
        # The button opens a new tab via target=_blank rather than navigating
        # the Canvas page away. The new tab lands at /lti/connect_course at
        # top level where session cookies behave as first-party.
        expect(response.body).to include('target="_blank"')
        expect(response.body).to include('/lti/connect_course?ltik=ltik-abc')
      end

      it 'renders the minimal lti_iframe layout (no dashboard navbar)' do
        get '/lti', params: { ltik: 'ltik-abc' }
        # nav_root is mounted by the application layout and renders the
        # React navbar; the lti_iframe layout omits it so we don't
        # mislead signed-in users with the iframe's logged-out state.
        expect(response.body).not_to include('nav_root')
      end

      it 'does not touch session (cookies in iframes are partitioned)' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(session['ltik']).to be_nil
      end

      # The landing is guaranteed stale once the user completes the new-tab
      # flow, so it offers the same re-launch link as the waiting states.
      it 'offers a check-again re-launch link carrying the ltik' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('Check again')
        expect(response.body).to include('href="/lti?ltik=ltik-abc"')
      end

      # The launch token identifies the Canvas course without a signed-in
      # user, so the landing can report link state to the instructor.
      it 'tells an instructor the course is not yet linked' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('not yet linked')
      end

      # The ltik authenticates the launch on its own, so once the course is
      # linked an instructor gets the real status view right in the iframe —
      # no sign-in bounce for read-only state.
      it 'renders the status view instead of the landing once the course is linked' do
        course = create(:course)
        lti_binding_for(course)
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to render_template('lti_launch/instructor_status')
        expect(response.body).to include(course.title)
        expect(response.body).not_to include('not yet linked')
      end

      context 'for a student launch' do
        let(:role) { 'Learner' }

        it 'omits the not-linked notice (students cannot set up the link)' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).not_to include('not yet linked')
        end
      end

      context 'when the LTIAAS idtoken fetch fails' do
        before do
          stub_request(:get, idtoken_url).to_return(status: 500, body: 'oops')
        end

        it 'still renders the landing, without the notice' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Open the Wiki Education Dashboard')
          expect(response.body).not_to include('not yet linked')
        end
      end
    end

    context 'when signed in as an instructor' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      before { approve_identity_link }

      context 'with no existing course binding' do
        before { approve_identity_link }

        it 'renders the setup view for a connected instructor' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Set up the Wiki Education Dashboard')
        end

        context 'and the instructor has approved not-yet-ended courses' do
          let(:campaign) { create(:campaign) }

          before do
            current = create(:course, slug: 'School/Active_Course_(2026)',
                                      title: 'Active Course',
                                      start: 1.week.ago, end: 2.months.from_now)
            future = create(:course, slug: 'School/Upcoming_Course_(2026)',
                                     title: 'Upcoming Course',
                                     start: 1.month.from_now, end: 4.months.from_now)
            past = create(:course, slug: 'School/Archived_Course_(2025)',
                                   title: 'Archived Course',
                                   start: 2.years.ago, end: 1.year.ago)
            unapproved = create(:course, slug: 'School/Pending_Course_(2026)',
                                         title: 'Pending Course',
                                         start: 1.week.ago, end: 2.months.from_now)
            withdrawn = create(:course, slug: 'School/Withdrawn_Course_(2026)',
                                        title: 'Withdrawn Course', withdrawn: true,
                                        start: 1.week.ago, end: 2.months.from_now)
            [current, future, past, withdrawn].each do |c|
              CampaignsCourses.create!(course: c, campaign: campaign)
            end
            [current, future, past, unapproved, withdrawn].each do |c|
              CoursesUsers.create!(user: user, course: c,
                                   role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
            end
          end

          it 'renders a select populated with approved, not-yet-ended courses' do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body).to include('<select', 'name="course_slug"')
            expect(response.body).to include('School/Active_Course_(2026)')
            expect(response.body).to include('School/Upcoming_Course_(2026)')
            expect(response.body).not_to include('School/Archived_Course_(2025)')
            expect(response.body).not_to include('School/Pending_Course_(2026)')
            expect(response.body).not_to include('School/Withdrawn_Course_(2026)')
          end

          it 'excludes a course already linked to another Canvas course' do
            linked = create(:course, slug: 'School/Linked_Course_(2026)',
                                     title: 'Linked Course',
                                     start: 1.week.ago, end: 2.months.from_now)
            CampaignsCourses.create!(course: linked, campaign: campaign)
            CoursesUsers.create!(user: user, course: linked,
                                 role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
            LtiCourseBinding.create!(course: linked, lms_id: 'platform-x', lms_family: 'canvas',
                                     lms_context_id: 'other-ctx', lms_resource_link_id: 'other-rl')
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body).to include('School/Active_Course_(2026)')
            expect(response.body).not_to include('School/Linked_Course_(2026)')
          end
        end

        context 'and the instructor has exactly one linkable course' do
          let(:solo_user) { create(:user, username: 'SoloInstructor') }

          before do
            allow_any_instance_of(ApplicationController)
              .to receive(:current_user).and_return(solo_user)
            solo_campaign = create(:campaign, slug: 'solo-campaign', title: 'Solo')
            only = create(:course, slug: 'School/Only_Course_(2026)', title: 'Only Course',
                                   start: 1.week.ago, end: 2.months.from_now)
            CampaignsCourses.create!(course: only, campaign: solo_campaign)
            CoursesUsers.create!(user: solo_user, course: only,
                                 role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
            approve_identity_link(solo_user)
          end

          it 'preselects the sole course (no blank prompt) so the instructor can just link' do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body)
              .to include("<option selected=\"selected\" value=\"School/Only_Course_(2026)\"")
            # No empty prompt option when there's only one choice.
            expect(response.body).not_to include('<option value=""></option>')
          end
        end

        # An empty picker has two distinct causes with different next steps:
        # no Dashboard courses at all (create one) vs. courses that just
        # aren't linkable yet (wait for approval).
        context 'and the instructor has no Dashboard courses at all' do
          it 'offers the create-a-course path instead of the approval message' do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body).not_to include('name="course_slug"')
            expect(response.body).to include('Create a course on the Dashboard')
            expect(response.body).to include('href="/"')
            expect(response.body).not_to include('approved by Wiki Education staff')
          end
        end

        context 'and the instructor has courses, but none approved and current' do
          before do
            unapproved = create(:course, slug: 'School/Pending_Course_(2026)',
                                         title: 'Pending Course',
                                         start: 1.week.ago, end: 2.months.from_now)
            CoursesUsers.create!(user: user, course: unapproved,
                                 role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
          end

          it 'hides the link-existing form and explains the approval requirement' do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body).not_to include('name="course_slug"')
            expect(response.body).to include('approved by Wiki Education staff')
            expect(response.body).to include('href="/"')
          end
        end
      end

      context 'with a bound course' do
        before { approve_identity_link }

        let!(:course) { create(:course) }
        let!(:binding) do
          lti_binding_for(course)
        end

        # Rather than redirecting into the full dashboard (which renders
        # logged-out inside the Canvas iframe), the nav launch confirms the
        # link and shows sync status, with a new-tab link out to the course.
        it 'renders the link confirmation / sync status view' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/instructor_status')
          expect(response.body).to include(course.title)
          expect(response.body).to include("/courses/#{course.slug}")
          expect(response.body).to include('target="_blank"')
        end

        # The refresh link re-requests the launch URL inside the iframe only,
        # so the Canvas page stays put while the sync status re-renders.
        it 'includes an in-iframe refresh link carrying the ltik' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Refresh')
          expect(response.body).to include('href="/lti?ltik=ltik-abc"')
        end

        # Roster size and connected accounts are reported as separate numbers:
        # one count under a roster-sounding label showed "0" for a course whose
        # roster sync had just discovered its students.
        it 'shows the roster and connected-account counts and the last sync time' do
          student = create(:user, username: 'Stu')
          LtiContext.create!(user: student, lti_course_binding: binding,
                             user_lti_id: 'lti-stu', lms_id: 'platform-x',
                             roles: ['vocab/membership#Learner'], linked_at: 2.hours.ago)
          LtiContext.create!(lti_course_binding: binding, user_id: nil,
                             user_lti_id: 'lti-unconnected', lms_id: 'platform-x',
                             roles: ['vocab/membership#Learner'])
          binding.update!(last_roster_sync_at: 5.minutes.ago)

          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include(I18n.t('lms_integration.roster_students'))
          expect(response.body).to include(I18n.t('lms_integration.connected_accounts'))
          expect(response.body).to include('5 minutes ago')
        end

        it 'reports "Not yet synced" before any sync or student link' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Not yet synced')
        end

        it 'enqueues a roster sync' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(LtiRosterSyncWorker).to have_received(:perform_async)
            .with(binding.id)
        end

        # Roster and grade sync run on different cadences, so the status view
        # reports each separately and offers an on-demand grade-sync trigger.
        it 'shows separate roster/grade sync rows and a grade-sync trigger' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Roster sync')
          expect(response.body).to include('Grade sync')
          expect(response.body).to include('Sync grades')
          expect(response.body).to include('action="/lti/sync_grades"')
          # The trigger must carry the ltik so the POST re-authenticates the
          # launch (the iframe has no Rails session to fall back on).
          expect(response.body).to match(/name="ltik"[^>]*value="ltik-abc"/)
        end

        it 'shows the last grade sync time separately from the roster sync' do
          binding.update!(last_roster_sync_at: 5.minutes.ago,
                          last_grade_sync_at: 1.hour.ago)
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('5 minutes ago')
          expect(response.body).to include('about 1 hour ago')
        end

        describe 'POST /lti/sync_grades' do
          before { allow(LtiGradeSyncWorker).to receive(:perform_async) }

          it 'enqueues a grade sync and re-renders the status view' do
            post '/lti/sync_grades', params: { ltik: 'ltik-abc' }
            expect(LtiGradeSyncWorker).to have_received(:perform_async).with(binding.id)
            expect(response).to render_template('lti_launch/instructor_status')
          end

          # This POST comes from a button inside the Canvas iframe and re-renders
          # in place, so its response has to be framable. It wasn't: the concern
          # registered its own `after_action :allow_iframe`, ActiveSupport
          # treated it as a duplicate of the controller's and kept only the
          # latter, and the button produced "refused to connect" — a 200 the
          # browser wouldn't render. The stale-ltik path below passed throughout,
          # because it calls allow_iframe directly.
          it 'clears X-Frame-Options so the re-render is framable' do
            post '/lti/sync_grades', params: { ltik: 'ltik-abc' }
            expect(response).to have_http_status(:ok)
            expect(response.headers).not_to have_key('X-Frame-Options')
          end

          # The grade-sync POST is a grade sync only — it must not also re-queue
          # a roster sync the way the status launch (GET) does.
          it 'does not enqueue a roster sync' do
            post '/lti/sync_grades', params: { ltik: 'ltik-abc' }
            expect(LtiRosterSyncWorker).not_to have_received(:perform_async)
          end

          it 'redirects to the login error page without an ltik' do
            post '/lti/sync_grades'
            expect(response).to redirect_to('/errors/login_error')
            expect(LtiGradeSyncWorker).not_to have_received(:perform_async)
          end

          context 'when the launcher is a student, not an instructor' do
            let(:role) { 'Learner' }

            it 'refuses to sync (instructor-only) and enqueues nothing' do
              post '/lti/sync_grades', params: { ltik: 'ltik-abc' }
              expect(response).to redirect_to('/errors/login_error')
              expect(LtiGradeSyncWorker).not_to have_received(:perform_async)
            end
          end

          # The button keeps working long after the 24h ltik dies, and the POST
          # comes from inside the iframe — where a redirect to the login-error
          # page (X-Frame-Options) renders as a blank frame.
          context 'when the ltik has expired on a stale tab' do
            before do
              stub_request(:get, idtoken_url).to_return(status: 401, body: 'expired')
            end

            it 'renders the in-frame launch error for the framed POST' do
              post '/lti/sync_grades', params: { ltik: 'ltik-stale' },
                                       headers: { 'Sec-Fetch-Dest' => 'iframe' }
              expect(response).to have_http_status(422)
              expect(response).to render_template('lti_launch/launch_error')
              expect(response.headers).not_to have_key('X-Frame-Options')
              expect(LtiGradeSyncWorker).not_to have_received(:perform_async)
            end

            it 'keeps the login-error redirect for a top-level POST' do
              post '/lti/sync_grades', params: { ltik: 'ltik-stale' }
              expect(response).to redirect_to('/errors/login_error')
            end
          end
        end

        # Deep-link-first: before anything is imported, the status view points
        # the instructor at the Modules import path.
        it 'shows the import next-step when no assignments are imported yet' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('lti-iframe__next-step')
        end

        # Canvas creates every imported assignment and its module unpublished,
        # and students can't see an unpublished assignment — so importing isn't
        # the end of setup, and the import step gives way to the publish step
        # rather than to nothing.
        it 'replaces the import next-step with the publish step once an assignment is imported' do
          LtiLineItem.create!(lti_course_binding: binding,
                              gradable_type: LtiLineItem::SETUP_TYPE,
                              lineitem_id: 'https://canvas/li/setup', label: 'Wikipedia account')
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).not_to include(I18n.t('lti.status.import_next_step.header'))
          expect(response.body).to include(I18n.t('lti.status.publish_next_step.header'))
        end
      end
    end

    context 'when signed in as a student' do
      let(:role) { 'Learner' }
      let!(:course) { create(:course) }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      context 'with no bound course' do
        before { approve_identity_link }

        it 'renders the "instructor not done yet" view' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('being set up')
        end

        it 'offers a check-again re-launch link carrying the ltik' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Check again')
          expect(response.body).to include('href="/lti?ltik=ltik-abc"')
        end
      end

      context 'with a bound course and student already enrolled' do
        before { approve_identity_link }

        before do
          lti_binding_for(course)
          CoursesUsers.create!(user: user, course: course,
                               role: CoursesUsers::Roles::STUDENT_ROLE)
        end

        it 'redirects to the bound course without re-enrolling' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to redirect_to("/courses/#{course.slug}")
        end

        # Firefox re-grants the session inside the Canvas iframe after the
        # top-level login, and the course page's X-Frame-Options makes an
        # in-iframe redirect a hard dead end there — so framed launches get
        # an in-iframe status view with a new-tab link instead.
        it 'renders the in-iframe student status view for a framed launch' do
          get '/lti', params: { ltik: 'ltik-abc' },
                      headers: { 'Sec-Fetch-Dest' => 'iframe' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/student_status')
          expect(response.body).to include("/courses/#{course.slug}")
          expect(response.body).to include('target="_blank"')
        end

        # Linking is taught before timeline-building, so a student can launch
        # a course with no timeline content — which used to render a header
        # and nothing else.
        it 'explains the empty state when the course has no timeline content yet' do
          get '/lti', params: { ltik: 'ltik-abc' },
                      headers: { 'Sec-Fetch-Dest' => 'iframe' }
          expect(response.body)
            .to include(CGI.escapeHTML(I18n.t('lti.student_overview.empty')))
        end
      end

      context 'with a bound course and student not yet enrolled' do
        before { approve_identity_link }

        before do
          course.campaigns << Campaign.first
          lti_binding_for(course)
        end

        it 'enrolls the student and redirects to the course' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .to change(CoursesUsers, :count).by(1)
          expect(response).to redirect_to("/courses/#{course.slug}")
        end
      end

      context 'with a bound course that has not yet been approved' do
        before { approve_identity_link }

        before do
          # No campaign attached → JoinCourse#student_joining_before_approval?
          # returns true → enrollment is silently skipped without our handling.
          lti_binding_for(course)
        end

        it 'renders the pending-approval view and does not enroll the student' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('awaiting Wiki Education approval')
        end
      end

      # With the course-navigation tab off (the placement default we want),
      # a student's only launch is the assignment itself — so that launch has
      # to carry the enrollment the nav launch used to.
      context 'when the only launch is an assignment' do
        before { approve_identity_link }

        let(:idtoken) do
          base = idtoken_for(role)
          base['launch']['resourceLink'] = { 'id' => 'rl-assignment-1' }
          base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/setup' }
          base
        end
        let!(:bound) do
          lti_binding_for(course)
        end

        before do
          LtiLineItem.create!(lti_course_binding: bound, gradable_type: LtiLineItem::SETUP_TYPE,
                              lineitem_id: 'https://canvas/li/setup', label: 'Wikipedia account')
        end

        context 'on an approved course' do
          before { course.campaigns << Campaign.first }

          it 'enrolls the student and still renders the drill-down' do
            expect { get '/lti', params: { ltik: 'ltik-abc' } }
              .to change(CoursesUsers, :count).by(1)
            expect(response).to render_template('lti_launch/assignment_view_setup')
          end

          # The context has to land on the bound binding: grade sync and the
          # rosters read that row, so a link anywhere else is invisible to them.
          it "links the student's LtiContext to the bound binding" do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(bound.lti_contexts.where(user_id: user.id)).to exist
          end

          it 'does not re-enroll a student who already joined' do
            enroll_student
            expect { get '/lti', params: { ltik: 'ltik-abc' } }
              .not_to change(CoursesUsers, :count)
            expect(response).to render_template('lti_launch/assignment_view_setup')
          end
        end

        # An unapproved course can't enroll anyone, and the drill-down would
        # just look empty — explain instead, as the nav launch does.
        it 'renders pending-approval when the course is not approved yet' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response.body).to include('awaiting Wiki Education approval')
        end
      end

      context 'with a bound course that has been withdrawn' do
        before { approve_identity_link }

        before do
          course.campaigns << Campaign.first
          course.update!(withdrawn: true)
          lti_binding_for(course)
          allow(Sentry).to receive(:capture_message)
        end

        it 'renders the generic enrollment-error view and reports to Sentry' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Couldn&#39;t enroll")
          # Offers a re-launch retry for when the underlying issue clears.
          expect(response.body).to include('Check again')
          expect(response.body).to include('href="/lti?ltik=ltik-abc"')
          expect(Sentry).to have_received(:capture_message)
            .with('LTI student launch JoinCourse failure',
                  hash_including(extra: hash_including(failure: 'withdrawn')))
        end
      end
    end

    it 'allows the response to render in an iframe' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get '/lti', params: { ltik: 'ltik-abc' }
      expect(response.headers).not_to have_key('X-Frame-Options')
    end

    # Canvas is the only platform this integration is built and tested for: the
    # deep-link flow, the AGS submission_type extension, and the role mapping are
    # all Canvas-shaped. A launch from anything else fails closed instead of
    # reaching that code.
    context 'when the launch comes from a non-Canvas platform' do
      let(:idtoken) do
        base = idtoken_for(role)
        base['platform']['productFamilyCode'] = 'moodle'
        base
      end

      before { allow(Sentry).to receive(:capture_exception) }

      it 'refuses the launch' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:forbidden)
      end

      it 'creates no binding for it' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiCourseBinding, :count)
      end

      # The anonymous path normally degrades to the landing page on any error;
      # this one has to fail closed instead.
      it 'refuses the signed-out launch too rather than showing the landing' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:forbidden)
        expect(response.body).not_to include('Open the Wiki Education Dashboard')
      end

      it 'reports it, since only a registered platform can reach this' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(Sentry).to have_received(:capture_exception)
      end
    end

    # Canvas maps ObserverEnrollment to Mentor. While Mentor counted as staff, an
    # observer's course-nav launch rendered the instructor status panel — roster
    # counts, last-sync state, and the Sync grades trigger.
    context 'when the launch role is one the integration does not serve' do
      before { approve_identity_link }

      let(:role) { 'Mentor' }
      let!(:course) { create(:course) }
      let!(:binding) do
        lti_binding_for(course)
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'does not render the instructor status view' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:forbidden)
        expect(response).to render_template('lti_launch/enrollment_error')
      end

      it 'does not enroll them in the Dashboard course' do
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .not_to change(CoursesUsers, :count)
      end

      it 'does not kick off a roster sync on their behalf' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(LtiRosterSyncWorker).not_to have_received(:perform_async)
      end
    end

    # Two Canvas members in one course can't share a Wikipedia account: grade
    # sync would post the same progress at both of their gradebook rows.
    context 'when the signed-in user is already linked to another LMS identity' do
      let!(:course) { create(:course) }
      let!(:binding) do
        lti_binding_for(course)
      end

      before do
        allow(Sentry).to receive(:capture_exception)
        LtiContext.create!(user_lti_id: 'lti-someone-else', lti_course_binding: binding,
                           lms_id: 'platform-x', user:, linked_at: 1.day.ago)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'renders the enrollment-error view instead of raising' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:conflict)
        expect(response).to render_template('lti_launch/enrollment_error')
      end

      it 'creates no second context and reports the conflict' do
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiContext, :count)
        expect(Sentry).to have_received(:capture_exception)
      end

      it 'still renders inside the Canvas iframe' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.headers).not_to have_key('X-Frame-Options')
      end
    end

    # The ltik is in the URL, so a launch that relinked to whoever is signed in
    # would let a student share their link and collect someone else's progress
    # against their own Canvas grade.
    context 'when this LMS identity is already linked to a different user' do
      let(:original) { create(:user, username: 'First Account') }
      let!(:course) { create(:course) }
      let!(:binding) do
        lti_binding_for(course)
      end

      before do
        allow(Sentry).to receive(:capture_exception)
        LtiContext.create!(user_lti_id: 'lti-user-1', lti_course_binding: binding,
                           lms_id: 'platform-x', user: original, linked_at: 1.day.ago)
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'refuses the launch rather than moving the link' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:conflict)
        expect(LtiContext.find_by(user_lti_id: 'lti-user-1').user).to eq(original)
      end
    end

    # An unrescued LTIAAS failure 500s with the default X-Frame-Options,
    # which the Canvas iframe shows as a blank "refused to connect".
    context 'when LTIAAS refuses the ltik (expired launch on a stale tab)' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow(Sentry).to receive(:capture_exception)
        stub_request(:get, idtoken_url).to_return(status: 401, body: 'expired')
      end

      it 'renders the in-frame launch error instead of a blank 500' do
        get '/lti', params: { ltik: 'ltik-stale' }
        expect(response).to have_http_status(:bad_gateway)
        expect(response).to render_template('lti_launch/launch_error')
        expect(response.headers).not_to have_key('X-Frame-Options')
      end

      it 'offers a re-launch retry carrying the ltik' do
        get '/lti', params: { ltik: 'ltik-stale' }
        expect(response.body).to include('Check again')
        expect(response.body).to include('href="/lti?ltik=ltik-stale"')
      end

      # A 24h token expiring is routine, not an incident.
      it 'does not report the routine expiry to Sentry' do
        get '/lti', params: { ltik: 'ltik-stale' }
        expect(Sentry).not_to have_received(:capture_exception)
      end
    end

    context 'when LTIAAS itself fails mid-launch (5xx)' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow(Sentry).to receive(:capture_exception)
        stub_request(:get, idtoken_url).to_return(status: 503, body: 'down')
      end

      it 'renders the in-frame launch error and reports the outage' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:bad_gateway)
        expect(response).to render_template('lti_launch/launch_error')
        expect(response.headers).not_to have_key('X-Frame-Options')
        expect(Sentry).to have_received(:capture_exception)
      end
    end

    # A redirect to the login-error page is itself blocked by that page's
    # X-Frame-Options, so framed refusals must render in place.
    context 'when a framed launch arrives without an ltik' do
      it 'renders the in-frame error rather than redirecting to a frame-blocked page' do
        get '/lti', headers: { 'Sec-Fetch-Dest' => 'iframe' }
        expect(response).to have_http_status(422)
        expect(response).to render_template('lti_launch/launch_error')
        expect(response.headers).not_to have_key('X-Frame-Options')
      end
    end
  end

  # Connecting a Dashboard account to a Canvas identity is the user's decision,
  # not a side effect of launching. A launch used to link whichever account the
  # browser was signed into, and because the link is write-once, the mistake
  # could only be undone by staff clearing the row.
  describe 'identity approval' do
    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    describe 'a launch with nothing connected yet' do
      it 'asks instead of linking' do
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiContext, :count)
        expect(response).to render_template('lti_launch/connect_identity')
      end

      it 'names both the Canvas course and the account being connected' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('WRIT 2010')
        expect(response.body).to include(user.username)
      end

      # The binding is this launch's identity as a Canvas course, and predates any
      # decision about who is connecting to it.
      it 'still records the binding' do
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .to change(LtiCourseBinding, :count).by(1)
      end

      it 'offers a way to connect a different account' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include(destroy_user_session_path)
      end
    end

    describe 'POST /lti/connect_identity' do
      it 'connects the signed-in account and continues into the launch' do
        expect { post '/lti/connect_identity', params: { ltik: 'ltik-abc' } }
          .to change(LtiContext, :count).by(1)
        context = LtiContext.last
        expect(context.user).to eq(user)
        expect(context.user_lti_id).to eq('lti-user-1')
        expect(context.linked_at).to be_present
        expect(response).not_to render_template('lti_launch/connect_identity')
      end

      it 'fills in an NRPS-discovered row rather than creating a second one' do
        binding = lti_binding_for(nil)
        discovered = LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-user-1',
                                        lms_id: 'platform-x',
                                        roles: ['vocab/membership#Learner'])

        expect { post '/lti/connect_identity', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiContext, :count)
        expect(discovered.reload.user).to eq(user)
      end

      # The whole point of the step: the roles a launch refreshes are fine to
      # take automatically, but the identity itself needs the click.
      it 'is the only path that creates a link' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(LtiContext.where(user_id: user.id)).not_to exist
      end

      it 'requires an ltik' do
        post '/lti/connect_identity'
        expect(response).to redirect_to('/errors/login_error')
        expect(LtiContext.count).to eq(0)
      end

      it 'refuses when nobody is signed in' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        post '/lti/connect_identity', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:forbidden)
        expect(LtiContext.count).to eq(0)
      end

      it 'is idempotent once the account is connected' do
        approve_identity_link
        expect { post '/lti/connect_identity', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiContext, :count)
        expect(response).to have_http_status(:ok)
      end
    end

    # Write-once in both directions. Both conflicts are refused before anything
    # is written, and the identity-taken one names its self-service remedy —
    # which is what the launch path used to withhold, sending an instructor the
    # student-facing "contact your instructor" copy instead.
    describe 'when the Canvas identity belongs to another Dashboard account' do
      before do
        approve_identity_link(create(:user, username: 'SomeoneElse'))
      end

      it 'refuses the launch and names the remedy' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:conflict)
        expect(response.body)
          .to include(CGI.escapeHTML(I18n.t('lti.setup.duplicate_link_error')))
      end

      # Naming the account would identify the remedy precisely, but it would put
      # a Wikipedia username in front of whoever holds the launch URL.
      it 'does not disclose which account holds the link' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).not_to include('SomeoneElse')
      end

      it 'refuses the approval POST too, leaving the existing link alone' do
        expect { post '/lti/connect_identity', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiContext, :count)
        expect(response).to have_http_status(:conflict)
        expect(LtiContext.find_by(user_lti_id: 'lti-user-1').user.username)
          .to eq('SomeoneElse')
      end
    end

    describe 'when this account already holds another Canvas identity here' do
      before do
        binding = lti_binding_for(nil)
        LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-someone-else',
                           lms_id: 'platform-x', user:, linked_at: 1.day.ago,
                           roles: ['vocab/membership#Learner'])
      end

      # No self-service remedy for this one — staff have to clear the link — so
      # it keeps the generic view.
      it 'refuses without offering the sign-in-again remedy' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:conflict)
        expect(response.body)
          .not_to include(CGI.escapeHTML(I18n.t('lti.setup.duplicate_link_error')))
      end
    end
  end

  describe 'POST /lti/setup' do
    let(:instructor) { create(:user) }
    # Production-realistic: only an approved (campaign-assigned, not withdrawn),
    # not-yet-ended course is linkable, which is the set the picker is built from.
    let!(:course) { create(:course, end: 2.months.from_now) }
    let!(:binding) do
      LtiCourseBinding.create!(
        lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
    end

    def approve(a_course)
      create(:campaigns_course, campaign: Campaign.first || create(:campaign), course: a_course)
    end

    before do
      approve(course)
      allow_any_instance_of(ApplicationController)
        .to receive(:current_user).and_return(instructor)
    end

    context "when the current_user is an instructor on the course" do
      before do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'binds the course' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(binding.reload.course).to eq(course)
        expect(response).to redirect_to("/courses/#{course.slug}")
      end

      # Deep-link-first is the only layout, so setup has nothing to choose and
      # nothing to auto-create: the instructor imports columns from Canvas.
      it 'creates no gradebook columns' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(LtiLineItem.count).to eq(0)
      end

      it 'enqueues a roster sync after binding' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(LtiRosterSyncWorker).to have_received(:perform_async).with(binding.id)
      end

      it 'sets the canvas_integration flag on the linked course' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(course.reload.flags[:canvas_integration]).to be true
      end

      it 'sets a flash notice so the course page confirms the link' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(flash[:notice]).to be_present
      end

      # A framed setup POST (Firefox keeps the session in the iframe) can't
      # redirect to the unframable course page; the status view IS the
      # confirmation there, and it must be allowed to render in the frame.
      it 'renders the in-iframe status view when submitted from the iframe' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug },
                           headers: { 'Sec-Fetch-Dest' => 'iframe' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/instructor_status')
        expect(response.headers).not_to have_key('X-Frame-Options')
        expect(binding.reload.course).to eq(course)
      end
    end

    # A link conflict during setup is shown to the *instructor* running it, so
    # it must not reuse the student-facing "couldn't enroll you / contact your
    # instructor" view.
    context "when the instructor's Canvas identity is already linked to another account" do
      before do
        allow(Sentry).to receive(:capture_exception)
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        LtiContext.create!(user_lti_id: 'lti-user-1', lti_course_binding: binding,
                           lms_id: 'platform-x',
                           user: create(:user, username: 'FirstDashboardAccount'),
                           linked_at: 1.day.ago)
      end

      # The one conflict with a self-service remedy: signing back in with the
      # Dashboard account that was connected first.
      it 're-renders setup naming the duplicate-link remedy, and does not bind' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(:conflict)
        expect(response).to render_template('lti_launch/setup')
        expect(response.body)
          .to include(CGI.escapeHTML(I18n.t('lti.setup.duplicate_link_error')))
        expect(binding.reload.course).to be_nil
      end
    end

    context 'when the instructor Dashboard account is already linked to another Canvas user' do
      before do
        allow(Sentry).to receive(:capture_exception)
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        LtiContext.create!(user_lti_id: 'lti-someone-else', lti_course_binding: binding,
                           lms_id: 'platform-x', user: instructor, linked_at: 1.day.ago)
      end

      it 're-renders setup with the instructor-facing conflict error, not the student one' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(:conflict)
        expect(response).to render_template('lti_launch/setup')
        expect(response).not_to render_template('lti_launch/enrollment_error')
        expect(response.body)
          .to include(CGI.escapeHTML(I18n.t('lti.setup.link_conflict_error')))
        expect(binding.reload.course).to be_nil
      end
    end

    # The binding comes from the verified launch, not the form. Submitting
    # another binding's id used to be enough to bind an unrelated Canvas
    # course — one the submitter has no launch for — to a course they teach.
    context 'when a binding id for a different Canvas course is submitted' do
      let!(:other_binding) do
        LtiCourseBinding.create!(
          lms_id: 'platform-x', lms_family: 'canvas',
          lms_context_id: 'someone-elses-ctx', lms_resource_link_id: 'rl-1'
        )
      end

      before do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'leaves that binding alone and binds only the launch it verified' do
        post '/lti/setup', params: {
          ltik: 'ltik-abc', binding_id: other_binding.id, course_slug: course.slug
        }
        expect(other_binding.reload.course).to be_nil
        expect(binding.reload.course).to eq(course)
      end
    end

    context 'when the ltik is missing' do
      it 'redirects to the login error page and does not bind' do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        post '/lti/setup', params: { binding_id: binding.id, course_slug: course.slug }
        expect(response).to redirect_to('/errors/login_error')
        expect(binding.reload.course).to be_nil
      end
    end

    context 'when the verified launch is not an instructor launch' do
      let(:role) { 'Learner' }

      it 'returns 403 and does not bind' do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(:forbidden)
        expect(binding.reload.course).to be_nil
      end
    end

    # Moving a claimed binding isn't reachable from any flow (an instructor
    # launch for a bound binding renders the status view), so a POST that
    # would move one is a replay or tampering.
    context 'when the launch binding is already linked to another course' do
      let!(:already_linked) { create(:course, slug: 'other/Course_(2026)', end: 2.months.from_now) }

      before do
        approve(already_linked)
        binding.update!(course: already_linked)
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'returns 403 and leaves the existing link in place' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(:forbidden)
        expect(binding.reload.course).to eq(already_linked)
      end
    end

    context 'when the chosen course is already linked to another Canvas course' do
      before do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        LtiCourseBinding.create!(
          course: course, lms_id: 'platform-x', lms_family: 'canvas',
          lms_context_id: 'other-ctx', lms_resource_link_id: 'other-rl'
        )
      end

      it 're-renders setup without binding, instead of raising a 500' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(422)
        expect(binding.reload.course).to be_nil
        expect(response.body).to include('lti-setup__error')
      end
    end

    context "when the current_user is not an instructor on the course" do
      it 'returns 403 and does not bind' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: course.slug }
        expect(response).to have_http_status(:forbidden)
        expect(binding.reload.course).to be_nil
      end
    end

    # An unapproved or already-ended course never appears in the picker, so
    # the server refuses it too rather than trusting the submitted slug.
    context 'when the chosen course is not in the linkable set' do
      let!(:ended) { create(:course, slug: 'past/Course_(2015)', end: 1.month.ago) }

      before do
        approve(ended)
        CoursesUsers.create!(user: instructor, course: ended,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'returns 403 and does not bind' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: ended.slug }
        expect(response).to have_http_status(:forbidden)
        expect(binding.reload.course).to be_nil
      end
    end

    context 'when the course slug does not exist' do
      it 'returns 403' do
        post '/lti/setup', params: { ltik: 'ltik-abc', course_slug: 'nope/missing' }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'GET /lti/connect_course' do
    it 'requires a ltik' do
      get '/lti/connect_course'
      expect(response).to redirect_to('/errors/login_error')
    end

    it 'stashes the ltik in session and renders an auto-POSTing OAuth form' do
      get '/lti/connect_course', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:ok)
      expect(session['ltik']).to eq('ltik-abc')
      expect(response.body).to include('action="/users/auth/mediawiki"')
      expect(response.body).to include('method="post"')
      # Form auto-submits via JS so users with cookies enabled never see
      # the manual fallback button.
      expect(response.body).to include('document.getElementById')
    end
  end

  describe 'assignment-context launch' do
    # LTIAAS forwards every core launch to /lti, so an assignment_view
    # placement launch arrives here and is dispatched by the presence of
    # the canvas_assignment_id custom claim.
    let!(:course) { create(:course) }
    let(:week) { create(:week, course: course, order: 2) }
    let(:exercise_module) do
      create(:training_module, slug: 'eval-ex', name: 'Evaluate Wikipedia', kind: 1,
                               settings: { 'sandbox_location' => 'Evaluate_an_Article' })
    end
    let(:block) do
      create(:block, week: week, order: 0, title: 'Evaluate Wikipedia',
                     training_module_ids: [exercise_module.id],
                     content: '<p>Read an article and evaluate its sourcing.</p>')
    end
    let!(:binding) do
      lti_binding_for(course)
    end
    let!(:line_item) do
      LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                          gradable_id: block.id, lineitem_id: 'https://canvas/li/7',
                          label: 'Wk2 Evaluate Wikipedia')
    end
    let(:idtoken) do
      base = idtoken_for(role)
      base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/7' }
      base['custom'] = { 'canvas_assignment_id' => 'canvas-assign-55' }
      base
    end

    before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

    context 'when signed in as an instructor' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      before { approve_identity_link }

      it 'dispatches /lti to the roster for the matched block line item' do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Wk2 Evaluate Wikipedia')
        expect(response.body).to include('Stu Dent')
        expect(response.body).to include('User:Stu_Dent/Evaluate_an_Article')
      end

      it 'backfills canvas_assignment_id from the launch line-item URL' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(line_item.reload.canvas_assignment_id).to eq('canvas-assign-55')
      end

      # The sandbox-preview script's user-visible strings come from the locale
      # file (the lti_iframe layout loads no i18n JS bundle, so the view
      # serializes them into the inline script).
      it 'passes the sandbox-preview messages from the locale file into the script' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('"not_found":"No sandbox found"')
        expect(response.body).to include('"error":"Sandbox failed to load"')
      end

      it 'is also reachable via the /lti/assignment_view fallback route' do
        get '/lti/assignment_view', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Wk2 Evaluate Wikipedia')
      end

      context 'when the launch carries the line-item URL but no custom variable' do
        let(:idtoken) do
          base = idtoken_for(role)
          base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/7' }
          base
        end

        it 'still dispatches to the roster via the line-item URL' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Wk2 Evaluate Wikipedia')
        end
      end

      context 'when the launch carries only the deep-link resource marker' do
        # A deep-link-created assignment reliably carries only custom.resource —
        # no scoped lineItemId, no canvas_assignment_id — so the resource marker
        # must dispatch it, or the launch falls through to the course page.
        let(:idtoken) do
          idtoken_for(role).merge('custom' => { 'resource' => "Block:#{block.id}" })
        end

        it 'dispatches to the roster via the resource marker' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Wk2 Evaluate Wikipedia')
        end
      end

      context 'when it launches through its own (deep-link) resource link' do
        # A deep-link-created assignment launches via a distinct resource link.
        # Since a binding models a Canvas *course*, the launch resolves to the
        # context's already-bound binding rather than minting a row per
        # assignment — those strays stranded the launcher's LtiContext where
        # grade sync never reads it, and left the bound row's service
        # credentials to go stale.
        let(:idtoken) do
          base = idtoken_for(role)
          base['launch']['resourceLink'] = { 'id' => 'rl-deep-link-1' }
          base['custom'] = { 'resource' => "Block:#{block.id}" }
          base
        end

        it 'resolves the roster via the context-bound binding' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Wk2 Evaluate Wikipedia')
        end

        it 'creates no separate binding for the assignment resource link' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(LtiCourseBinding, :count)
          expect(LtiCourseBinding.where(lms_context_id: 'canvas-77').count).to eq(1)
        end

        # The resource link is a snapshot of the latest launch, not part of the
        # binding's identity, so it follows this launch onto the one row.
        it 'refreshes the resource-link snapshot on the context-bound binding' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(binding.reload.lms_resource_link_id).to eq('rl-deep-link-1')
        end
      end

      context 'when only the launch line item (tagged) identifies the gradable' do
        # Canvas doesn't echo the content-item custom, so the launch carries no
        # marker — only its own AGS lineItemId. Resolve reads the gradable off the
        # line item's tag and repoints the local row to this deep-link column.
        let(:idtoken) do
          base = idtoken_for(role)
          base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/deep' }
          base
        end

        before do
          allow(LtiServiceSession).to receive(:new).and_return(
            instance_double(LtiServiceSession, list_line_items: [
                              { 'id' => 'https://canvas/li/deep', 'tag' => "Block:#{block.id}" }
                            ])
          )
        end

        it 'binds the deep-link column via its tag and renders the roster' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Wk2 Evaluate Wikipedia')
          expect(line_item.reload.lineitem_id).to eq('https://canvas/li/deep')
        end
      end

      context 'when the launch matches no known line item' do
        let(:idtoken) do
          idtoken_for(role).merge('custom' => { 'canvas_assignment_id' => 'unmatched' })
        end

        it 'renders the orphan view' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('There is no Dashboard content')
        end
      end

      context 'on the first launch of a deep-link-created assignment' do
        let!(:deep_block) do
          create(:block, week:, order: 1, title: 'Draft your article',
                         training_module_ids: [exercise_module.id])
        end
        let(:idtoken) do
          base = idtoken_for(role)
          base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/NEW' }
          base['custom'] = { 'resource' => "Block:#{deep_block.id}" }
          base
        end

        it 'binds a new line item from the resource marker and renders its view' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .to change(LtiLineItem, :count).by(1)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('Draft your article')
          expect(LtiLineItem.find_by(lineitem_id: 'https://canvas/li/NEW').gradable_id)
            .to eq(deep_block.id)
        end
      end
    end

    context 'when signed in as a student' do
      let(:role) { 'Learner' }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        # A student with sandbox/training state is one who is already enrolled;
        # the enroll-on-assignment-launch path has its own specs below.
        enroll_student
        approve_identity_link
      end

      it 'renders the student panel with their own sandbox link' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('User:')
        expect(response.body).to include('Evaluate_an_Article')
        expect(response.body).to include('Your sandbox')
      end

      it "renders the block's timeline body as the in-iframe description" do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('Read an article and evaluate its sourcing.')
      end

      # Sandbox exercises keep their how-to in the exercise module's training
      # page, so the panel links to it prominently alongside the sandbox.
      it 'links to the exercise module instructions alongside the sandbox' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('Launch instructions')
        expect(response.body).to match(%r{href="/training/[^"]*/eval-ex})
      end

      context 'for a dedicated-page exercise (e.g. fact verification)' do
        let(:exercise_module) do
          create(:training_module, slug: 'fact-check-ex', name: 'Fact verification', kind: 1,
                                   settings: { 'exercise_path' => 'verify_claim' })
        end

        it 'renders status plus a button to the exercise page, nothing else' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("/courses/#{course.slug}/verify_claim")
          expect(response.body).to include('Open exercise')
          # No sandbox actions and no block-body description for these.
          expect(response.body).not_to include('Your sandbox')
          expect(response.body).not_to include('Read an article and evaluate its sourcing.')
        end

        it 'reads "Not started" before the student takes a claim' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Not started')
        end

        # Taking a claim creates a VerificationClaimAssignment; until the
        # response is submitted (which marks the module complete) the exercise
        # is in progress, not "Not started".
        it 'reads "In progress" once the student has taken a claim' do
          claim = VerificationClaim.create!(sentence: 'A cited claim.', wiki: Wiki.default_wiki)
          VerificationClaimAssignment.create!(user: user, course: course,
                                              verification_claim: claim)
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('In progress')
          expect(response.body).not_to include('Not started')
        end
      end
    end

    # The stage's outcome is which article each student took on, so the roster
    # reports that instead of a completion pill it can't act on.
    context 'when the launch resolves to an article-selection exercise' do
      let(:exercise_module) do
        create(:training_module, slug: 'choose-topic-from-list-exercise',
                                 name: 'Choose your article from a list', kind: 1)
      end

      it "lists each student's assigned article in place of the status" do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)
        Assignment.create!(course:, user: student, wiki: course.home_wiki,
                           role: Assignment::Roles::ASSIGNED_ROLE,
                           article_title: 'Chromatic aberration')

        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include('Chromatic aberration')
        expect(response.body).to include(I18n.t('lti.assignment_view.roster.assigned_article'))
        expect(response.body).not_to include(I18n.t('lti.assignment_view.roster.status'))
      end

      it 'says so for a student who has not chosen an article yet' do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)

        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response.body).to include(I18n.t('lti.assignment_view.no_article_yet'))
      end
    end

    context 'when not signed in (in-iframe launch, partitioned cookies)' do
      # The ltik authenticates the launch, so assignment drill-downs render
      # in the iframe with the viewer resolved from the LTI identity.
      it 'renders the instructor roster without a Rails session' do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/assignment_view')
        expect(response.body).to include('Stu Dent')
      end

      context 'as a student with a linked Wikipedia account' do
        let(:role) { 'Learner' }

        it 'renders their own panel, resolved from the launch LTI identity' do
          LtiContext.create!(user: user, lti_course_binding: binding,
                             user_lti_id: 'lti-user-1', lms_id: 'platform-x',
                             roles: ['vocab/membership#Learner'], linked_at: Time.current)
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/assignment_view')
          expect(response.body).to include('Your sandbox')
        end
      end

      context 'as a student who has not linked a Wikipedia account' do
        let(:role) { 'Learner' }

        it 'renders the landing so the new-tab flow can link them' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/sign_in_to_continue')
        end
      end
    end

    context 'when the launch resolves to the "Wikipedia account" setup column' do
      before { approve_identity_link }

      let!(:setup_item) do
        LtiLineItem.create!(lti_course_binding: binding,
                            gradable_type: LtiLineItem::SETUP_TYPE,
                            lineitem_id: 'https://canvas/li/setup',
                            label: 'Wikipedia account')
      end
      let(:idtoken) do
        base = idtoken_for(role)
        base['services']['assignmentAndGrades'] = { 'lineItemId' => 'https://canvas/li/setup' }
        base
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'renders the connection roster, counting not-yet-connected members' do
        linked_student = create(:user, username: 'LinkedStu')
        CoursesUsers.create!(user: linked_student, course: course,
                             role: CoursesUsers::Roles::STUDENT_ROLE,
                             real_name: 'Linda Linked')
        LtiContext.create!(user: linked_student, lti_course_binding: binding,
                           user_lti_id: 'lti-linked', lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)
        LtiContext.create!(lti_course_binding: binding, user_lti_id: 'lti-pending-1',
                           lms_id: 'platform-x', roles: ['vocab/membership#Learner'])
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/assignment_view_setup')
        # Connected rows show the Dashboard-side identity: the enrollment's
        # real name plus the Wikipedia username (same as the Students tab).
        expect(response.body).to include('Linda Linked')
        expect(response.body).to include('LinkedStu')
        expect(response.body).to include('Connected')
        # The unlinked member has no legible identity (anonymized mode), so it
        # is counted in the pending callout rather than shown as an opaque id.
        expect(response.body).not_to include('lti-pending-1')
        expect(response.body).to include('lti-iframe__next-step')
      end

      context 'as a student' do
        let(:role) { 'Learner' }

        before { enroll_student }

        it 'renders their own connected confirmation, not the roster' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/assignment_view_setup')
          expect(response.body).to include('Connected')
          expect(response.body).not_to include('lti-assignment-roster')
        end

        it 'shows their username linked to their Dashboard student details view' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include(user.username)
          expect(response.body)
            .to include("/courses/#{course.slug}/students/articles/#{user.url_encoded_username}")
        end
      end
    end

    # Peer review had no way into Canvas before this column: no exercise module
    # means DeepLinkableGradables never offered it.
    context 'when the launch resolves to the peer-review column' do
      before { approve_identity_link }

      let!(:peer_review_item) do
        LtiLineItem.create!(lti_course_binding: binding,
                            gradable_type: LtiLineItem::PEER_REVIEW_TYPE,
                            lineitem_id: 'https://canvas/li/peer-review',
                            label: 'Peer review')
      end
      let(:idtoken) do
        base = idtoken_for(role)
        base['services']['assignmentAndGrades'] = {
          'lineItemId' => 'https://canvas/li/peer-review'
        }
        base
      end

      before do
        course.flags[:peer_review_count] = 2
        course.save!
      end

      it 'renders the roster with each student’s reviews-done count' do
        student = create(:user, username: 'Rev Iewer')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-rev',
                           lms_id: 'platform-x', roles: ['vocab/membership#Learner'],
                           linked_at: Time.current)
        review = Assignment.create!(course:, user: student, wiki: course.home_wiki,
                                    role: Assignment::Roles::REVIEWING_ROLE,
                                    article_title: 'Someone elses article')
        review.update_sandbox_status(:review,
                                     AssignmentPipeline::SandboxStatuses::EXISTS_IN_USERSPACE)

        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/assignment_view_peer_review')
        expect(response.body).to include('Rev Iewer')
      end

      context 'as a student' do
        let(:role) { 'Learner' }

        it 'lists their own reviews with the page each belongs on' do
          enroll_student
          Assignment.create!(course:, user:, wiki: course.home_wiki,
                             role: Assignment::Roles::REVIEWING_ROLE,
                             article_title: 'Someone elses article')

          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/assignment_view_peer_review')
          expect(response.body).to include('Someone elses article')
          expect(response.body).to include('_Peer_Review')
        end

        it 'says so when no reviews have been assigned to them yet' do
          enroll_student
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body)
            .to include(I18n.t('lti.assignment_view.peer_review.none_assigned'))
        end
      end
    end

    context 'when the launch resolves to the "Wikipedia trainings" roll-up column' do
      before { approve_identity_link }

      let(:training_mod) do
        create(:training_module, slug: 'wiki-intro', name: 'Wiki intro', kind: 0)
      end
      let!(:training_block) do
        create(:block, week: week, order: 1, title: 'Trainings',
                       training_module_ids: [training_mod.id])
      end
      let!(:trainings_item) do
        LtiLineItem.create!(lti_course_binding: binding,
                            gradable_type: LtiLineItem::TRAINING_PROGRESS_TYPE,
                            lineitem_id: 'https://canvas/li/trainings',
                            label: 'Wikipedia trainings')
      end
      let(:idtoken) do
        base = idtoken_for(role)
        base['services']['assignmentAndGrades'] =
          { 'lineItemId' => 'https://canvas/li/trainings' }
        base
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'renders each linked student\'s completed-trainings count' do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x',
                           roles: ['vocab/membership#Learner'], linked_at: Time.current)
        TrainingModulesUsers.create!(user: student, training_module: training_mod,
                                     completed_at: 1.day.ago)
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/assignment_view_trainings')
        expect(response.body).to include('Stu Dent')
        expect(response.body).to include('1 of 1 trainings completed')
        # The descriptive content — what the roll-up covers — lives in the
        # iframe: each module linked, with its students-completed count.
        expect(response.body).to include('Wiki intro')
        expect(response.body)
          .to include("/training/#{course.training_library_slug}/wiki-intro")
        expect(response.body).to include('1 / 1')
      end

      context 'as a student' do
        let(:role) { 'Learner' }

        before { enroll_student }

        it 'renders their own progress with a link out to the course timeline' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response).to render_template('lti_launch/assignment_view_trainings')
          expect(response.body).to include('0 of 1 trainings completed')
          expect(response.body).to include("/courses/#{course.slug}")
        end

        it 'lists each training with status and a link to the module itself' do
          TrainingModulesUsers.create!(user: user, training_module: training_mod,
                                       completed_at: 1.day.ago)
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response.body).to include('Wiki intro')
          expect(response.body).to include('Completed')
          expect(response.body)
            .to include("/training/#{course.training_library_slug}/wiki-intro")
        end
      end
    end
  end

  describe 'GET /lti/deep_link (picker)' do
    let!(:course) { create(:course) }
    let!(:week) { create(:week, course:, order: 1) }
    let(:exercise_module) {
 create(:training_module, slug: 'biblio', name: 'Bibliography', kind: 1) }
    let!(:exercise_block) do
      create(:block, week:, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    def bind_course!
      lti_binding_for(course)
    end

    before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

    it 'requires a ltik' do
      get '/lti/deep_link'
      expect(response).to redirect_to('/errors/login_error')
    end

    # e.g. a Canvas observer or designer opening the picker placement: the
    # refusal stays a 403, but a bare `head :forbidden` rendered as a blank
    # page inside Canvas's picker modal, so it now carries an explanation.
    it 'forbids non-instructor launches with an in-frame message, not a blank page' do
      allow_any_instance_of(LtiSession).to receive(:instructor?).and_return(false)
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('lti_launch/deep_link_forbidden')
      expect(response.headers).not_to have_key('X-Frame-Options')
    end

    it 'renders the not-yet-linked landing (with the open-Dashboard button) when unbound' do
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('lti_launch/sign_in_to_continue')
      expect(response.body).to include('not yet linked')
      expect(response.body).to include('Open the Wiki Education Dashboard')
      expect(response.body).to include('/lti/connect_course?ltik=ltik-abc')
    end

    # The picker's "not yet linked" landing sends the instructor out to
    # /lti/connect_course with the deep-linking launch's own ltik — which is
    # the only way to link a course when the nav tab is off. A deep-linking
    # request carries no resourceLink claim, which used to blow up binding
    # creation (NoMethodError) the moment that ltik came back through /lti.
    context 'when the launch carries no resourceLink (a deep-linking request)' do
      let(:idtoken) do
        base = idtoken_for(role)
        base['launch'].delete('resourceLink')
        base
      end

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      # Binding creation is what the examples below are about, so they launch
      # without a connected account (the binding is created either way — the
      # approval step comes after it).
      it 'renders the setup view rather than erroring' do
        approve_identity_link
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response).to render_template('lti_launch/setup')
      end

      it 'creates one context-scoped binding the setup form can bind' do
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .to change(LtiCourseBinding, :count).by(1)
        expect(LtiCourseBinding.last.lms_resource_link_id)
          .to eq(LtiSession::DEEP_LINKING_RESOURCE_LINK_ID)
      end

      it 'reuses the bound binding once the course is linked' do
        bind_course!
        expect { get '/lti', params: { ltik: 'ltik-abc' } }
          .not_to change(LtiCourseBinding, :count)
      end
    end

    it 'renders the picker listing the bound course gradables' do
      bind_course!
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('lti_launch/deep_link_picker')
      expect(response.body).to include('Wk1 Find sources')
      expect(response.body).to include("Block:#{exercise_block.id}")
      # Single-item placement (no accept_multiple) => radios, not checkboxes.
      expect(response.body).to include('type="radio"')
      # Renders inside Canvas's deep-linking picker iframe, so it must be framable.
      expect(response.headers).not_to have_key('X-Frame-Options')
    end

    it 'omits gradables that already have an active gradebook column' do
      binding = bind_course!
      LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                          gradable_id: exercise_block.id,
                          lineitem_id: 'https://canvas/li/existing', label: 'Wk1 Find sources')
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response.body).not_to include("Block:#{exercise_block.id}")
    end

    # A pending reservation (another picker submission awaiting discovery)
    # holds its gradable off the menu just like a bound column.
    it 'omits gradables held by a pending reservation' do
      binding = bind_course!
      LtiLineItem.create!(lti_course_binding: binding, gradable_type: 'Block',
                          gradable_id: exercise_block.id, label: 'Wk1 Find sources')
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response.body).not_to include("Block:#{exercise_block.id}")
    end

    context 'when the placement accepts multiple content items (Modules bulk flow)' do
      let(:raw_idtoken) do
        { 'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings' =>
          { 'accept_multiple' => true } }
      end

      it 'renders a pre-checked multi-select picker' do
        bind_course!
        get '/lti/deep_link', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Import Wikipedia assignments')
        expect(response.body).to include('type="checkbox"')
        expect(response.body).to include('name="resources[]"')
        expect(response.body).to include('checked="checked"')
      end
    end
  end

  describe 'POST /lti/deep_link/select' do
    let(:form_url) { "https://#{ltiaas_domain}/api/deeplinking/form" }
    let(:form_html) { '<form id="dl"></form><script>document.forms[0].submit()</script>' }
    let!(:course) { create(:course) }
    let!(:week) { create(:week, course:, order: 1) }
    let(:exercise_module) {
 create(:training_module, slug: 'biblio', name: 'Bibliography', kind: 1) }
    let!(:exercise_block) do
      create(:block, week:, order: 0, title: 'Find sources',
                     training_module_ids: [exercise_module.id])
    end

    before do
      allow(LtiLineItemSyncWorker).to receive(:perform_in)
      lti_binding_for(course)
    end

    it 'requires a ltik' do
      post '/lti/deep_link/select', params: { resource: "Block:#{exercise_block.id}" }
      expect(response).to redirect_to('/errors/login_error')
    end

    it 'refuses non-instructor submissions with the same in-frame message as the picker' do
      allow_any_instance_of(LtiSession).to receive(:instructor?).and_return(false)
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:forbidden)
      expect(response).to render_template('lti_launch/deep_link_forbidden')
    end

    it 'returns the self-submitting form for a valid chosen gradable' do
      stub = stub_request(:post, form_url)
             .to_return(status: 200, body: { 'form' => form_html }.to_json,
                        headers: { 'Content-Type' => 'application/json' })
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(form_html)
      expect(stub).to have_been_requested
      # The self-submitting form also renders inside the picker iframe.
      expect(response.headers).not_to have_key('X-Frame-Options')
    end

    it 'rejects a resource that is not one of the bound course gradables' do
      post '/lti/deep_link/select', params: { ltik: 'ltik-abc', resource: 'Block:999999' }
      expect(response).to have_http_status(422)
    end

    # The local row for the new column only lands minutes after the form
    # submits (discovery by tag, or a launch-time bind), so the accepted
    # selection is reserved with a pending row before the form is returned —
    # otherwise a duplicate of this POST inside that window would still see
    # the gradable as offerable.
    it 'reserves the chosen gradable with a pending row before returning the form' do
      stub_request(:post, form_url)
        .to_return(status: 200, body: { 'form' => form_html }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      expect do
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      end.to change(LtiLineItem.pending, :count).by(1)
      row = LtiLineItem.last
      expect(row.gradable_id).to eq(exercise_block.id)
      expect(row.lineitem_id).to be_nil
      expect(row.label).to eq('Wk1 Find sources')
    end

    # The reservation commits before the LTIAAS form call, and discovery is
    # only scheduled after a successful build — so a failed build must release
    # the reservation itself, or the instructor's immediate retry 422s against
    # their own dead reservation for the rest of the pending lease.
    it 'releases the reservation when the form build fails, so a retry succeeds' do
      stub_request(:post, form_url)
        .to_return({ status: 500, body: 'boom' },
                   { status: 200, body: { 'form' => form_html }.to_json,
                     headers: { 'Content-Type' => 'application/json' } })
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:bad_gateway)
      expect(LtiLineItem.pending.count).to eq(0)

      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(form_html)
      expect(LtiLineItem.pending.count).to eq(1)
    end

    # Failures after the form build — the discovery enqueue (Redis down) or
    # the render — must release the reservation too: Canvas never received
    # the form, so nothing will ever adopt it.
    it 'releases the reservation when the discovery enqueue fails' do
      stub_request(:post, form_url)
        .to_return(status: 200, body: { 'form' => form_html }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      allow(LtiLineItemSyncWorker).to receive(:perform_in)
        .and_raise(RuntimeError, 'redis down')
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:internal_server_error)
      expect(LtiLineItem.pending.count).to eq(0)

      allow(LtiLineItemSyncWorker).to receive(:perform_in)
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      expect(response).to have_http_status(:ok)
    end

    # The double-submit / replayed-POST race: the first request's reservation
    # is already committed, so the duplicate must lose even though no bound
    # column exists yet.
    context 'when a concurrent request already reserved the chosen gradable' do
      before do
        LtiLineItem.create!(
          lti_course_binding: LtiCourseBinding.find_by(course:),
          gradable_type: 'Block', gradable_id: exercise_block.id,
          label: 'Wk1 Find sources'
        )
      end

      it 'refuses the submission' do
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(response).to have_http_status(422)
      end

      # A bare 422 renders as a blank panel inside Canvas's import dialog. Most
      # refusals here are invisible by nature (Canvas discards the losing half of
      # a double-submit), but a picker left open until its reservation expired
      # refuses an ordinary click and has to say so in the frame.
      it 'explains the refusal in-frame rather than returning a blank body' do
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(response.body).to include(I18n.t('lti.deep_link.unavailable_header'))
        expect(response.body).to include(I18n.t('lti.deep_link.unavailable_explanation'))
      end

      it 'never asks LTIAAS to build a content-item form for it' do
        stub = stub_request(:post, form_url)
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(stub).not_to have_been_requested
      end
    end

    # The picker hides gradables that already have a column, but the submission
    # used to validate only course membership — so a replayed or hand-built POST
    # could ask for one anyway and mint a second Canvas assignment with the same
    # tag. Submission now recomputes the same offerable set the picker showed.
    context 'when the chosen gradable already has an active gradebook column' do
      before do
        LtiLineItem.create!(
          lti_course_binding: LtiCourseBinding.find_by(course:),
          gradable_type: 'Block', gradable_id: exercise_block.id,
          lineitem_id: 'https://canvas/li/existing', label: 'Find sources'
        )
      end

      it 'refuses the submission' do
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(response).to have_http_status(422)
      end

      it 'never asks LTIAAS to build a content-item form for it' do
        stub = stub_request(:post, form_url)
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(stub).not_to have_been_requested
      end

      # An archived column means the gradable is back on the menu.
      it 'allows it again once the existing column is archived' do
        LtiLineItem.find_by(gradable_id: exercise_block.id).archive!
        stub_request(:post, form_url)
          .to_return(status: 200, body: { 'form' => form_html }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        expect(response).to have_http_status(:ok)
      end

      # The archived row occupies the (binding, gradable_key) unique slot, so
      # the re-import's reservation must re-use it — revived as pending, its
      # dead column identifier cleared — rather than collide with it.
      it 'revives the archived row as the pending reservation' do
        row = LtiLineItem.find_by(gradable_id: exercise_block.id)
        row.archive!
        stub_request(:post, form_url)
          .to_return(status: 200, body: { 'form' => form_html }.to_json,
                     headers: { 'Content-Type' => 'application/json' })
        expect do
          post '/lti/deep_link/select',
               params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
        end.not_to change(LtiLineItem, :count)
        expect(row.reload).to be_pending
        expect(row).not_to be_archived
      end
    end

    it 'schedules a line-item sync so the new column is discovered and bound' do
      stub_request(:post, form_url)
        .to_return(status: 200, body: { 'form' => form_html }.to_json,
                   headers: { 'Content-Type' => 'application/json' })
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc', resource: "Block:#{exercise_block.id}" }
      # at_least: creating the spec's blocks also fires the Block-edit hook
      # with identical arguments.
      expect(LtiLineItemSyncWorker).to have_received(:perform_in)
        .with(2.minutes, LtiCourseBinding.last.id).at_least(:once)
    end

    let!(:second_exercise_block) do
      create(:block, week:, order: 1, title: 'Draft your article',
                     training_module_ids: [exercise_module.id])
    end

    it 'rejects multiple resources when the placement accepts only one' do
      post '/lti/deep_link/select',
           params: { ltik: 'ltik-abc',
                     resources: ["Block:#{exercise_block.id}",
                                 "Block:#{second_exercise_block.id}"] }
      expect(response).to have_http_status(422)
    end

    context 'when the placement accepts multiple content items' do
      let(:raw_idtoken) do
        { 'https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings' =>
          { 'accept_multiple' => true } }
      end

      it 'posts one content item per selected resource' do
        stub = stub_request(:post, form_url)
               .with do |request|
                 items = JSON.parse(request.body)['contentItems']
                 items.length == 2 &&
                   items.map { |i| i['custom']['resource'] }.sort ==
                     ["Block:#{exercise_block.id}", "Block:#{second_exercise_block.id}"].sort
               end
               .to_return(status: 200, body: { 'form' => form_html }.to_json,
                          headers: { 'Content-Type' => 'application/json' })
        post '/lti/deep_link/select',
             params: { ltik: 'ltik-abc',
                       resources: ["Block:#{exercise_block.id}",
                                   "Block:#{second_exercise_block.id}"] }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include(form_html)
        expect(stub).to have_been_requested
      end

      it 'rejects an empty selection' do
        post '/lti/deep_link/select', params: { ltik: 'ltik-abc', resources: [] }
        expect(response).to have_http_status(422)
      end

      # Reject-the-whole-request semantics extend to reservations: when any
      # chosen gradable is already held, the submission is refused and no
      # pending row is left behind to block the instructor's own retry.
      it 'reserves nothing when one of the chosen gradables is already reserved' do
        LtiLineItem.create!(
          lti_course_binding: LtiCourseBinding.find_by(course:),
          gradable_type: 'Block', gradable_id: exercise_block.id,
          label: 'Wk1 Find sources'
        )
        expect do
          post '/lti/deep_link/select',
               params: { ltik: 'ltik-abc',
                         resources: ["Block:#{second_exercise_block.id}",
                                     "Block:#{exercise_block.id}"] }
        end.not_to change(LtiLineItem, :count)
        expect(response).to have_http_status(422)
      end
    end
  end

  describe 'feature flag gating' do
    before do
      allow(Features).to receive(:canvas_integration?).and_return(false)
    end

    it '404s on /lti when the flag is off' do
      get '/lti', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:not_found)
    end

    it '404s on /lti/connect_course when the flag is off' do
      get '/lti/connect_course', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:not_found)
    end

    it '404s on /lti/deep_link when the flag is off' do
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:not_found)
    end

    it '404s on /lti/deep_link/select when the flag is off' do
      post '/lti/deep_link/select', params: { ltik: 'ltik-abc', resource: 'Block:1' }
      expect(response).to have_http_status(:not_found)
    end
  end

  # A structural guard, not a behaviour test. Every framed action needs
  # X-Frame-Options cleared, and the way that breaks is silent: ActiveSupport's
  # callback chain treats a second `after_action :allow_iframe` as a duplicate
  # of the first and keeps only the last registration, so a concern declaring
  # one for its own action deletes the controller's list — for every OTHER
  # action too. The response stays 200 and only the browser notices.
  #
  # Asserting the whole set in one place is what makes that visible: a lost
  # registration shows up as actions missing from this set, and a new framed
  # action can't be added to the controller without being named here.
  describe 'the allow_iframe callback' do
    it 'covers exactly the actions that render inside the Canvas iframe' do
      registrations = LtiLaunchController._process_action_callbacks
                                         .select { |c| c.filter == :allow_iframe }
      expect(registrations.size).to eq(1)

      conditions = registrations.first.instance_variable_get(:@if)
      actions = conditions.filter_map { |c| c.instance_variable_get(:@actions) }.first
      expect(actions).to contain_exactly('launch', 'assignment_view', 'complete_setup',
                                         'connect_identity', 'deep_link', 'deep_link_select',
                                         'sync_grades')
    end
  end
end
