# frozen_string_literal: true

require 'rails_helper'

describe CourseCloneController do
  describe '#clone' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'when the user is the original instructor' do
      let!(:courses_user) do
        create(:courses_user, course_id: course.id, user_id: user.id,
                              role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
      end
      it 'clones the course' do
        expect_any_instance_of(CourseCloneManager).to receive(:clone!)
        post :clone, params: { id: course.id }
      end
    end
    context 'when the user is not the original instructor' do
      it 'returns a 401 error' do
        expect(CourseCloneManager).not_to receive(:new)
        post :clone, params: { id: course.id }
        expect(response.status).to eq(401)
      end
    end
  end
end
