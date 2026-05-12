# frozen_string_literal: true

require 'rails_helper'

describe LmsIntegrationStatusController, type: :request do
  let(:course) { create(:course, slug: 'School/Demo_(2026)') }
  let(:request_path) { "/courses/#{course.slug}/lms_integration_status.json" }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(viewer)
  end

  describe 'when the course has no canvas_integration flag set' do
    let(:viewer) { create(:user) }

    it 'returns bound: false' do
      get request_path
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq('bound' => false)
    end
  end

  describe 'when the course has the flag but no binding' do
    let(:viewer) { create(:user) }

    before { course.flags[:canvas_integration] = true; course.save! }

    it 'returns bound: false' do
      get request_path
      expect(JSON.parse(response.body)).to eq('bound' => false)
    end
  end

  describe 'when the course is bound to an LMS course' do
    let!(:binding) do
      LtiCourseBinding.create!(
        course: course, lms_id: 'platform-x', lms_family: 'canvas',
        lms_context_id: 'canvas-77', lms_resource_link_id: 'rl-99',
        lms_context_title: 'WRIT 2010', lms_platform_url: 'https://canvas.example.com',
        last_roster_sync_at: 2.hours.ago, last_grade_sync_at: 30.minutes.ago
      )
    end

    before { course.flags[:canvas_integration] = true; course.save! }

    context 'viewed by a course instructor' do
      let(:viewer) { create(:user) }

      before do
        CoursesUsers.create!(user: viewer, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'returns the staff payload with a clickable LMS course URL' do
        get request_path
        body = JSON.parse(response.body)
        expect(body['bound']).to be true
        expect(body['lms_name']).to eq('Canvas')
        expect(body['course_title']).to eq('WRIT 2010')
        expect(body['course_url']).to eq('https://canvas.example.com/courses/canvas-77')
        expect(body).to have_key('last_sync_at')
        expect(body).not_to have_key('last_roster_sync_at')
        expect(body['last_sync_error_present']).to be false
        expect(body['synced_students_count']).to eq(0)
      end

      it 'flags a recent grade-sync failure when one is recorded' do
        binding.update!(last_grade_sync_error: 'AGS POST failed: 401')
        get request_path
        expect(JSON.parse(response.body)['last_sync_error_present']).to be true
      end

      it 'counts only LtiContexts that have been linked to a User' do
        other_student = create(:user, username: 'OtherStudent')
        LtiContext.create!(lti_course_binding: binding, user: other_student,
                           user_lti_id: 'l1', lms_id: 'platform-x')
        LtiContext.create!(lti_course_binding: binding, user_id: nil,
                           user_lti_id: 'l2', lms_id: 'platform-x')
        get request_path
        expect(JSON.parse(response.body)['synced_students_count']).to eq(1)
      end
    end

    context 'viewed by a site admin who is not enrolled on the course' do
      let(:viewer) { create(:admin) }

      it 'returns the staff payload but no LMS course URL' do
        get request_path
        body = JSON.parse(response.body)
        expect(body['bound']).to be true
        expect(body['course_title']).to eq('WRIT 2010')
        expect(body).not_to have_key('course_url')
        expect(body).to have_key('last_sync_at')
      end
    end

    context 'viewed by a site admin who is an instructor on the course' do
      let(:viewer) { create(:admin) }

      before do
        CoursesUsers.create!(user: viewer, course: course,
                             role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      it 'treats them as instructor (includes the LMS course URL)' do
        get request_path
        body = JSON.parse(response.body)
        expect(body['course_url']).to eq('https://canvas.example.com/courses/canvas-77')
      end
    end

    context 'viewed by a linked student on the course' do
      let(:viewer) { create(:user) }
      let!(:context_row) do
        LtiContext.create!(lti_course_binding: binding, user: viewer,
                           user_lti_id: 'student-1', lms_id: 'platform-x')
      end

      before do
        CoursesUsers.create!(user: viewer, course: course,
                             role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'returns the student payload with the LMS course URL' do
        get request_path
        body = JSON.parse(response.body)
        expect(body['bound']).to be true
        expect(body['course_title']).to eq('WRIT 2010')
        expect(body['course_url']).to eq('https://canvas.example.com/courses/canvas-77')
        expect(body['my_linked']).to be true
      end

      it 'reports the most recent score push across the student\'s line items' do
        line_item = LtiLineItem.create!(lti_course_binding: binding,
                                        gradable_type: 'TrainingProgress',
                                        lineitem_id: 'li-1')
        LtiScoreSignature.create!(lti_line_item: line_item, lti_context: context_row,
                                  signature: 'sig-1', last_pushed_at: 1.hour.ago)
        get request_path
        expect(JSON.parse(response.body)['my_last_sync_at']).to be_present
      end

      it 'reports my_last_sync_at as null when nothing has been pushed yet' do
        get request_path
        expect(JSON.parse(response.body)['my_last_sync_at']).to be_nil
      end
    end

    context 'viewed by a Canvas-enrolled student who has not yet linked' do
      let(:viewer) { create(:user) }

      before do
        CoursesUsers.create!(user: viewer, course: course,
                             role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      it 'returns bound: true with my_linked: false (no sync state yet)' do
        get request_path
        body = JSON.parse(response.body)
        expect(body['bound']).to be true
        expect(body['my_linked']).to be false
      end
    end

    context 'viewed by a logged-in user with no role on the course' do
      let(:viewer) { create(:user) }

      it 'returns bound: false (panel not for them)' do
        get request_path
        expect(JSON.parse(response.body)).to eq('bound' => false)
      end
    end

    context 'viewed by an unauthenticated visitor' do
      let(:viewer) { nil }

      it 'returns bound: false' do
        get request_path
        expect(JSON.parse(response.body)).to eq('bound' => false)
      end
    end
  end
end
