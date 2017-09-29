# frozen_string_literal: true

require 'rails_helper'

describe AdminController do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  describe '#index' do
    it 'renders for admins' do
      allow(controller).to receive(:current_user).and_return(admin)
      get :index
      expect(response.status).to eq(200)
    end

    it 'redirects for non-admins' do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
      expect(response).to redirect_to(root_path)
    end
  end
end
