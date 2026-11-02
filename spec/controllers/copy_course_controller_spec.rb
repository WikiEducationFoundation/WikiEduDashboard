# frozen_string_literal: true

require 'rails_helper'

describe CopyCourseController, type: :request do
  describe '#index' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }

    context 'when the user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'shows the feature to copy the course' do
        get copy_course_path
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 error' do
        get copy_course_path
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#copy' do
    let(:admin) { create(:admin) }
    let(:subject) { post copy_course_path, params: { url: 'someurl.com' } }

    context 'when the copy fails for some reason' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow_any_instance_of(CopyCourse).to receive(:make_copy).and_return(
          { course: nil, error: 'An interesting error happened' }
        )
      end

      it 'renders the error' do
        subject
        expect(response).to redirect_to(copy_course_path)
        expect(flash[:error]).to eq('Course not created: An interesting error happened')
      end
    end

    context 'when the copy is successful' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow_any_instance_of(CopyCourse).to receive(:make_copy).and_return(
          { course: create(:basic_course), error: nil }
        )
      end

      it 'renders the success message' do
        subject
        expect(response).to redirect_to(%r{courses/none/Black_life_matters_\(none\)})
      end

      it 'records who made the copy' do
        subject
        course = Course.last
        expect(course.cloned_status).to eq(3)
        expect(course.flags[:copied_by_user_id]).to eq(admin.id)
      end
    end

    context 'when the copy collides with an existing course' do
      let(:existing) { create(:basic_course, cloned_status: 2, term: 'kept') }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
        allow_any_instance_of(CopyCourse).to receive(:make_copy).and_return(
          { course: existing, error: nil, existing: true }
        )
      end

      it 'leaves the existing course unchanged' do
        subject
        existing.reload
        expect(existing.cloned_status).to eq(2)
        expect(existing.term).to eq('kept')
        expect(existing.flags[:copied_by_user_id]).to be_nil
      end
    end

    context 'when the user is not logged in' do
      before { allow(Features).to receive(:wiki_ed?).and_return(false) }

      it 'refuses the copy' do
        expect(CopyCourse).not_to receive(:new)
        subject
        expect(response.status).to eq(401)
      end
    end
  end
end
