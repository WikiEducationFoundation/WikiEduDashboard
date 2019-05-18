# frozen_string_literal: true

require 'rails_helper'

describe CourseCloneController, type: :request do
  describe '#clone' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'when the user is the original instructor' do
      let!(:courses_user) do
        create(:courses_user, course_id: course.id, user_id: user.id,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end

      context 'json' do
        it 'clones the course' do
          expect_any_instance_of(CourseCloneManager).to receive(:clone!)
          post "/clone_course/#{course.id}", params: { format: :json, id: course.id }
        end
      end

      context 'html' do
        it 'clones the course' do
          expect_any_instance_of(CourseCloneManager).to receive(:clone!).and_return(course)
          post "/clone_course/#{course.id}", params: { format: :html, id: course.id }
        end
      end
    end

    context 'when the user is not the original instructor' do
      it 'returns a 401 error' do
        expect(CourseCloneManager).not_to receive(:new)
        post "/clone_course/#{course.id}", params: { format: :json, id: course.id }
        expect(response.status).to eq(401)
      end
    end
  end
end
