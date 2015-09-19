require 'rails_helper'

describe ErrorsController do
  let!(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'file_not_found' do
    it 'should have status 404' do
      get :file_not_found
      expect(response.status).to eq(404)
    end
  end

  describe 'unprocessable' do
    it 'should have status 422' do
      get :unprocessable
      expect(response.status).to eq(422)
    end
  end

  describe 'internal_server_error' do
    it 'should have status 500' do
      get :internal_server_error
      expect(response.status).to eq(500)
    end
  end
end
