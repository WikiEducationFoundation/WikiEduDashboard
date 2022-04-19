# frozen_string_literal: true

require 'rails_helper'

describe CopyCourseFromProductionController, type: :request do
  describe '#copy' do
    let(:user) { create(:user) }
    let(:admin) { create(:admin) }

    context 'when the user is an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      end

      it 'shows the feature to copy the course' do
        get '/course_copy_prod'
        expect(response.status).to eq(200)
      end
    end

    context 'when the user is not an admin' do
      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      end

      it 'returns a 401 error' do
        get '/course_copy_prod'
        expect(response.status).to eq(401)
      end
    end
  end
end
