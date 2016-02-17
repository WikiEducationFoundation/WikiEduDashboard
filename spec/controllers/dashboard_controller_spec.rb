require 'rails_helper'

describe DashboardController do
  describe '#index' do
    it 'redirects to landing page if user is not logged in' do
      get 'index'
      expect(response.status).to eq(302)
    end
  end
end
