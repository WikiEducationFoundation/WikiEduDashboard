# frozen_string_literal: true

require 'rails_helper'

describe ErrorsController, type: :request do
  let!(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end

  describe 'file_not_found' do
    it 'returns status 404' do
      get '/errors/file_not_found'
      expect(response.status).to eq(404)
    end
  end

  describe 'unprocessable' do
    it 'returns status 422' do
      get '/errors/unprocessable'
      expect(response.status).to eq(422)
    end
  end

  describe 'internal_server_error' do
    it 'returns status 500' do
      get '/errors/internal_server_error'
      expect(response.status).to eq(500)
    end
  end

  describe 'login_error' do
    it 'redirects to root path if user is logged in' do
      get '/errors/login_error'
      expect(response).to redirect_to(root_path)
    end
  end
end
