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

  before do
    ENV['LTIAAS_DOMAIN'] = ltiaas_domain
    ENV['LTIAAS_API_KEY'] = 'k'
    allow(Features).to receive(:canvas_integration?).and_return(true)
    stub_request(:get, idtoken_url)
      .to_return(status: 200, body: idtoken.to_json,
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
    end

    context 'when signed in as an instructor' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      context 'with no existing course binding' do
        it 'creates the binding and renders the setup view' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .to change(LtiCourseBinding, :count).by(1)
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
        end

        context 'and the instructor has zero approved not-yet-ended courses' do
          it 'hides the link-existing form and links to the dashboard home' do
            get '/lti', params: { ltik: 'ltik-abc' }
            expect(response.body).not_to include('name="course_slug"')
            expect(response.body).to include('approved by Wiki Education staff')
            expect(response.body).to include('href="/"')
          end
        end
      end

      context 'with a bound course' do
        let!(:course) { create(:course) }
        before do
          LtiCourseBinding.create!(
            course: course, lms_id: 'platform-x', lms_family: 'canvas',
            lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
          )
        end

        it 'redirects to the bound course' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to redirect_to("/courses/#{course.slug}")
        end

        it 'enqueues a roster sync' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(LtiRosterSyncWorker).to have_received(:perform_async)
            .with(LtiCourseBinding.last.id)
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
        it 'renders the "instructor not done yet" view' do
          get '/lti', params: { ltik: 'ltik-abc' }
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('being set up')
        end
      end

      context 'with a bound course and student already enrolled' do
        before do
          LtiCourseBinding.create!(
            course: course, lms_id: 'platform-x', lms_family: 'canvas',
            lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
          )
          CoursesUsers.create!(user: user, course: course,
                               role: CoursesUsers::Roles::STUDENT_ROLE)
        end

        it 'redirects to the bound course without re-enrolling' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to redirect_to("/courses/#{course.slug}")
        end
      end

      context 'with a bound course and student not yet enrolled' do
        before do
          course.campaigns << Campaign.first
          LtiCourseBinding.create!(
            course: course, lms_id: 'platform-x', lms_family: 'canvas',
            lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
          )
        end

        it 'enrolls the student and redirects to the course' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .to change(CoursesUsers, :count).by(1)
          expect(response).to redirect_to("/courses/#{course.slug}")
        end
      end

      context 'with a bound course that has not yet been approved' do
        before do
          # No campaign attached → JoinCourse#student_joining_before_approval?
          # returns true → enrollment is silently skipped without our handling.
          LtiCourseBinding.create!(
            course: course, lms_id: 'platform-x', lms_family: 'canvas',
            lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
          )
        end

        it 'renders the pending-approval view and does not enroll the student' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include('awaiting Wiki Education approval')
        end
      end

      context 'with a bound course that has been withdrawn' do
        before do
          course.campaigns << Campaign.first
          course.update!(withdrawn: true)
          LtiCourseBinding.create!(
            course: course, lms_id: 'platform-x', lms_family: 'canvas',
            lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
          )
          allow(Sentry).to receive(:capture_message)
        end

        it 'renders the generic enrollment-error view and reports to Sentry' do
          expect { get '/lti', params: { ltik: 'ltik-abc' } }
            .not_to change(CoursesUsers, :count)
          expect(response).to have_http_status(:ok)
          expect(response.body).to include("Couldn&#39;t enroll")
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
  end

  describe 'POST /lti/setup' do
    let(:instructor) { create(:user) }
    let!(:course) { create(:course) }
    let!(:binding) do
      LtiCourseBinding.create!(
        lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
    end

    before do
      allow_any_instance_of(ApplicationController)
        .to receive(:current_user).and_return(instructor)
    end

    context "when the current_user is an instructor on the course" do
      before do
        CoursesUsers.create!(user: instructor, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'binds the course and persists the chosen granularity' do
        post '/lti/setup', params: {
          binding_id: binding.id,
          course_slug: course.slug,
          gradebook_granularity: 'per_block'
        }
        binding.reload
        expect(binding.course).to eq(course)
        expect(binding.gradebook_granularity).to eq('per_block')
        expect(response).to redirect_to("/courses/#{course.slug}")
      end

      it 'enqueues a roster sync after binding' do
        post '/lti/setup', params: {
          binding_id: binding.id,
          course_slug: course.slug,
          gradebook_granularity: 'lumped'
        }
        expect(LtiRosterSyncWorker).to have_received(:perform_async).with(binding.id)
      end

      it 'sets the canvas_integration flag on the linked course' do
        post '/lti/setup', params: {
          binding_id: binding.id,
          course_slug: course.slug,
          gradebook_granularity: 'lumped'
        }
        expect(course.reload.flags[:canvas_integration]).to be true
      end
    end

    context "when the current_user is not an instructor on the course" do
      it 'returns 403 and does not bind' do
        post '/lti/setup', params: {
          binding_id: binding.id,
          course_slug: course.slug,
          gradebook_granularity: 'lumped'
        }
        expect(response).to have_http_status(:forbidden)
        expect(binding.reload.course).to be_nil
      end
    end

    context 'when the course slug does not exist' do
      it 'returns 403' do
        post '/lti/setup', params: {
          binding_id: binding.id,
          course_slug: 'nope/missing',
          gradebook_granularity: 'lumped'
        }
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
                     training_module_ids: [exercise_module.id])
    end
    let!(:binding) do
      LtiCourseBinding.create!(
        course: course, lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
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

      it 'dispatches /lti to the roster for the matched block line item' do
        student = create(:user, username: 'Stu Dent')
        LtiContext.create!(user: student, lti_course_binding: binding, user_lti_id: 'lti-stu',
                           lms_id: 'platform-x', name: 'Stu Dent',
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
      end

      it 'renders the student panel with their own sandbox link' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('User:')
        expect(response.body).to include('Evaluate_an_Article')
        expect(response.body).to include('Your sandbox')
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
      LtiCourseBinding.create!(
        course:, lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
    end

    before { allow(LtiLineItemSyncWorker).to receive(:perform_in) }

    it 'requires a ltik' do
      get '/lti/deep_link'
      expect(response).to redirect_to('/errors/login_error')
    end

    it 'forbids non-instructor launches' do
      allow_any_instance_of(LtiSession).to receive(:instructor?).and_return(false)
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'renders the unbound view when no course is linked to this context' do
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('lti_launch/deep_link_unbound')
    end

    it 'renders the picker listing the bound course gradables' do
      bind_course!
      get '/lti/deep_link', params: { ltik: 'ltik-abc' }
      expect(response).to have_http_status(:ok)
      expect(response).to render_template('lti_launch/deep_link_picker')
      expect(response.body).to include('Wk1 Find sources')
      expect(response.body).to include("Block:#{exercise_block.id}")
      # Renders inside Canvas's deep-linking picker iframe, so it must be framable.
      expect(response.headers).not_to have_key('X-Frame-Options')
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
      LtiCourseBinding.create!(
        course:, lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99'
      )
    end

    it 'requires a ltik' do
      post '/lti/deep_link/select', params: { resource: "Block:#{exercise_block.id}" }
      expect(response).to redirect_to('/errors/login_error')
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
end
