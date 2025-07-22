# frozen_string_literal: true

require 'rails_helper'

describe AdminController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    it 'renders for admins' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(admin)
      get '/admin'
      expect(response.status).to eq(200)
    end

    it 'redirects for non-admins' do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get '/admin'
      expect(response).to redirect_to(root_path)
    end
  end
end
