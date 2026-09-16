# frozen_string_literal: true

require 'rails_helper'

describe CourseCanvasCredentialsController, type: :request do
  let(:instructor) { create(:user, username: 'Prof') }
  let(:course) { create(:course, slug: 'School/Environmental_Policy_(2026)') }
  let(:path) { "/courses/#{course.slug}/canvas" }
  let(:viewer) { instructor }

  before do
    ENV['dashboard_url'] = 'dashboard.wikiedu.org'
    allow(Features).to receive_messages(canvas_integration?: true, lti_legacy_launches?: true)
    CoursesUsers.create!(user: instructor, course:, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    course.campaigns << Campaign.first
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(viewer)
  end

  # The page is unlisted, not secret: an obscure URL governs who finds it, and
  # nothing else. Everything below is the "nothing else".
  describe 'who may reach it' do
    context 'when legacy launches are disabled' do
      before { allow(Features).to receive(:lti_legacy_launches?).and_return(false) }

      it '404s, because where the feature is off the page does not exist' do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when the Canvas integration as a whole is disabled' do
      before { allow(Features).to receive(:canvas_integration?).and_return(false) }

      it '404s' do
        get path
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'when nobody is signed in' do
      let(:viewer) { nil }

      it 'refuses' do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the viewer is not an instructor on the course' do
      let(:viewer) { create(:user, username: 'Someone') }

      it 'refuses' do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the viewer is a student on the course' do
      let(:viewer) { create(:user, username: 'Student') }

      before { CoursesUsers.create!(user: viewer, course:, role: CoursesUsers::Roles::STUDENT_ROLE) }

      it 'refuses' do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    # An unapproved course cannot enroll anyone, so connecting it to Canvas
    # would produce a link that does nothing.
    context 'when the course is not approved yet' do
      before { course.campaigns.clear }

      it 'refuses' do
        get path
        expect(response).to have_http_status(:unauthorized)
      end
    end

    it '404s for a course that does not exist' do
      get '/courses/School/No_Such_Course_(2026)/canvas'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET, before any credentials exist' do
    it 'offers to generate them' do
      get path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Generate credentials')
    end
  end

  describe 'POST' do
    it 'issues a key for the course and shows the secret once' do
      expect { post path }.to change(LtiConsumerKey, :count).by(1)
      key = LtiConsumerKey.last
      expect(key.course).to eq(course)
      expect(key.user).to eq(instructor)
      expect(response.body).to include(key.key)
      expect(response.body).to include(key.secret)
      expect(response.body).to include('/lti/legacy/config.xml')
    end

    # Showing it once is policy, not a technical limit, so it needs a test: the
    # secret is decryptable on any later read and must not reach the page.
    it 'does not show the secret on a later visit' do
      post path
      secret = LtiConsumerKey.last.secret
      get path
      expect(response.body).not_to include(secret)
      expect(response.body).to include('Waiting for your first launch')
    end

    it 'replaces the previous key rather than adding a second live one' do
      post path
      first = LtiConsumerKey.last
      post path
      expect(first.reload).not_to be_active
      expect(LtiConsumerKey.active.where(course:).count).to eq(1)
    end
  end

  describe 'once the first launch has arrived' do
    before do
      post path
      LtiConsumerKey.last.record_launch!('canvas-instance-guid')
    end

    it 'reports the connection instead of the waiting state' do
      get path
      expect(response.body).to include('This course is connected to Canvas')
      expect(response.body).to include('Generate new credentials')
    end
  end

  # The anti-confusion guard: a course already connected through the standard
  # LTI 1.3 install has nothing to do here, and a second credential would only
  # create two ways for one course to be connected.
  describe 'when the course is already bound through the LTI 1.3 install' do
    before do
      LtiCourseBinding.create!(course:, lms_id: 'platform-x', lms_family: 'canvas',
                               lms_context_id: 'ctx-13', lms_resource_link_id: 'rl-13')
    end

    it 'says so and offers nothing' do
      get path
      expect(response.body)
        .to include('already connected to Canvas through the standard integration')
      expect(response.body).not_to include('Generate credentials')
    end

    it 'refuses to issue a key' do
      expect { post path }.not_to change(LtiConsumerKey, :count)
    end

    # The check is for a 1.3 binding specifically, not for "any binding and no
    # key": a course with a live 1.1 key that then gets the standard install
    # must not fall back to the waiting state and offer to regenerate.
    context 'when the course also has a 1.1 key from before' do
      before { LtiConsumerKey.generate_for(course:, user: instructor) }

      it 'still says so, rather than showing the waiting state' do
        get path
        expect(response.body)
          .to include('already connected to Canvas through the standard integration')
        expect(response.body).not_to include('Waiting for your first launch')
      end

      it 'still refuses to regenerate' do
        expect { post path }.not_to change(LtiConsumerKey, :count)
      end
    end
  end

  # A legacy binding is this page's own doing, so it is not "bound elsewhere".
  describe 'when the course is bound through its own LTI 1.1 launch' do
    before do
      post path
      LtiConsumerKey.last.record_launch!('canvas-instance-guid')
      LtiCourseBinding.create!(course:, lms_id: 'canvas-instance-guid', lms_family: 'canvas',
                               lms_context_id: 'ctx-11', lms_resource_link_id: 'rl-11',
                               lti_version: '1.2.0')
    end

    it 'reports the connection, not a conflict' do
      get path
      expect(response.body).to include('This course is connected to Canvas')
      expect(response.body).not_to include('standard integration')
    end
  end
end
