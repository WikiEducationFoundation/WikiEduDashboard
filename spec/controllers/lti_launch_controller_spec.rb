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
      it 'renders an iframe-friendly sign-in page that escapes to top-level' do
        get '/lti', params: { ltik: 'ltik-abc' }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Sign in to continue')
        # The button must break out of the iframe via target=_top, pointing
        # at /lti/connect_course so OAuth happens in the top-level window.
        expect(response.body).to include('target="_top"')
        expect(response.body).to include('/lti/connect_course?ltik=ltik-abc')
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
  end
end
