# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/wiki_course_edits')
require Rails.root.join('lib/wiki_preferences_manager')

describe SelfEnrollmentController, type: :request do
  let(:slug_params) { 'Wikipedia_Fellows/Basket-weaving_fellows_(summer_2018)' }
  let(:enroll_url) { "/courses/#{course.slug}/enroll/#{course.passcode}" }

  describe '#enroll_self' do
    subject { response.status }

    let(:course) { create(:course, end: Time.zone.today + 1.week, slug: slug_params) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }

    before do
      allow_any_instance_of(WikiCourseEdits).to receive(:update_course)
      allow_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'GET' do
      context 'when the course is not approved' do
        # Course is not in any campaigns, so enrollment will fail.
        it 'redirects without enrolling the user' do
          expect_any_instance_of(WikiCourseEdits).not_to receive(:enroll_in_course)
          get enroll_url, params: request_params
          expect(subject).to eq(302)
          expect(course.students.count).to eq(0)
        end
      end

      context 'when the course is approved' do
        before do
          course.campaigns << Campaign.first
        end

        context 'when the user is not enrolled yet' do
          it 'enrolls user (and redirects) and updates the user count' do
            expect(course.user_count).to eq(0)
            expect_any_instance_of(WikiCourseEdits).to receive(:enroll_in_course)
            expect_any_instance_of(WikiPreferencesManager).to receive(:enable_visual_editor)
            get enroll_url, params: request_params
            expect(subject).to eq(302)
            expect(course.students.count).to eq(1)
            expect(course.reload.user_count).to eq(1)
          end

          it 'returns a JSON success message' do
            expect_any_instance_of(WikiCourseEdits).to receive(:enroll_in_course)
            expect_any_instance_of(WikiPreferencesManager).to receive(:enable_visual_editor)
            get enroll_url, params: request_params.merge(format: :json)
            expect(subject).to eq(200)
            expect(course.students.count).to eq(1)
          end
        end

        context 'when the passcode is wrong' do
          let(:enroll_url) { "/courses/#{course.slug}/enroll/wrong_passcode" }

          it 'redirects a JSON request' do
            get enroll_url, params: request_params.merge(format: :json)
            expect(request).to redirect_to errors_incorrect_passcode_path(format: :json)
            expect(course.students.count).to eq(0)
          end
        end

        context 'when type is ClassroomProgramCourse' do
          context 'when the user is enrolled as an instructor' do
            before do
              create(:courses_user,
                     course_id: course.id,
                     user_id: user.id,
                     role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
            end

            it 'redirects without enrolling the user' do
              expect_any_instance_of(WikiCourseEdits).not_to receive(:enroll_in_course)
              get enroll_url, params: request_params
              expect(subject).to eq(302)
              expect(course.students.count).to eq(0)
            end

            it 'returns an JSON failure code and message' do
              get enroll_url, params: request_params.merge(format: :json)
              expect(subject).to eq(400)
              expect(course.students.count).to eq(0)
            end
          end
        end

        context 'when type is Editathon' do
          let(:course) { create(:editathon, end: Time.zone.today + 1.week, slug: slug_params) }

          context 'when the user is enrolled as a facilitator' do
            before do
              create(:courses_user,
                     course_id: course.id,
                     user_id: user.id,
                     role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
            end

            it 'enrolls user (and redirects) and updates the user count' do
              stub_oauth_edit
              get enroll_url, params: request_params
              expect(subject).to eq(302)
              expect(course.students.count).to eq(1)
            end
          end
        end

        context 'when the course has already ended' do
          let(:course) { create(:course, end: 1.day.ago, slug: slug_params) }

          it 'redirects without enrolling the user' do
            expect_any_instance_of(WikiCourseEdits).not_to receive(:enroll_in_course)
            get enroll_url, params: request_params
            expect(subject).to eq(302)
            expect(course.students.count).to eq(0)
          end

          it 'returns an JSON failure code and message' do
            get enroll_url, params: request_params.merge(format: :json)
            expect(subject).to eq(400)
            expect(course.students.count).to eq(0)
          end
        end
      end
    end

    # This is the HTTP verb that MS Word links use (for some reason)
    context 'HEAD' do
      it "doesn't error" do
        head enroll_url, params: request_params
        expect(subject).to eq(200)
      end
    end

    context 'when a user is not logged in' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
      end

      it 'returns a 401' do
        get(enroll_url, params: request_params)
        expect(response.body).to include('Please sign in')
        expect(response.status).to eq(401)
      end
    end
  end
end
