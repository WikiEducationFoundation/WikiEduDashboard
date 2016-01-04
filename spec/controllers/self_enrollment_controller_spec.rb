require 'rails_helper'

describe SelfEnrollmentController do
  describe '#enroll_self' do
    let!(:course) { create(:course) }
    let(:request_params) do
      { course_id: course.slug, passcode: course.passcode, titleterm: 'foobar' }
    end
    let(:user) { create(:user) }

    before do
      allow(WikiEdits).to receive(:update_course)
      allow(WikiEdits).to receive(:update_assignments)
      allow(controller).to receive(:current_user).and_return(user)
    end

    subject { response.status }

    context 'GET' do
      context 'when the user is not enrolled yet' do
        it 'enrolls user (and redirects)' do
          expect(WikiEdits).to receive(:enroll_in_course)
          get 'enroll_self', request_params
          expect(subject).to eq(302)
          expect(course.students.count).to eq(1)
        end
      end

      context 'when the user is enrolled as an instructor' do
        before do
          create(:courses_user,
                 course_id: course.id,
                 user_id: user.id,
                 role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
        end

        it 'redirects without enrolling the user' do
          expect(WikiEdits).not_to receive(:enroll_in_course)
          get 'enroll_self', request_params
          expect(subject).to eq(302)
          expect(course.students.count).to eq(0)
        end
      end
    end

    # This is the HTTP verb that MS Word links use (for some reason)
    context 'HEAD' do
      it "doesn't error" do
        head 'enroll_self', request_params
        expect(subject).to eq(200)
      end
    end

    context 'when a user is not logged in' do
      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'should redirect to mediawiki for OAuth' do
        expect(get 'enroll_self', request_params).to redirect_to(/.*mediawiki.*/)
      end
    end
  end
end
