require 'rails_helper'

describe ApplicationController do
  let(:user) { create(:user) }

  controller do
    def index
    end
  end

  describe '#new_session_path' do
    it 'should return the sign in path' do
      result = controller.send(:new_session_path, nil)
      expect(result).to eq('/sign_in')
    end
  end

  describe 'invalid authenticity tokens' do
    it 'should return a 401' do
      create(:cohort)
      exception = ActionController::InvalidAuthenticityToken.new('Unauthorized')
      allow(controller).to receive(:current_user).and_return(user)
      allow(controller).to receive(:check_for_unsupported_browser).and_raise(exception)
      get 'index'
      expect(response.status).to eq(401)
    end
  end
end
