# frozen_string_literal: true

require 'rails_helper'

describe CopyCourseFromProductionController, type: :request do
  describe '#copy' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }
    let(:existent_prod_course) do
      'https://dashboard.wikiedu.org/courses/University_of_South_Carolina/Invertebrate_Zoology_(Spring_2022)'
    end

    let(:subject) do
      copy route, params: { url: existent_prod_course }
    end

    context 'when the user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'copies the course' do
        subject
        expect(response.status).to eq(200)
        expect(Course.exists?(title: existent_prod_course)).to eq(true)
      end
    end

    context 'when the user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 error' do
        expect(CopyCourseFromProduction).not_to receive(:new)
        get '/course_copy_prod'
        expect(response.status).to eq(401)
      end
    end
  end
end
