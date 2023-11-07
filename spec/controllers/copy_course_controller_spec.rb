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
        expect(response).to redirect_to(copy_course_path)
        expect(flash[:notice]).to eq('Course Black life matters was created.'\
                                     '&nbsp;<a href="/courses/none/Black_life_'\
                                     'matters_(none)">Go to course</a>')
      end
    end
  end
end
