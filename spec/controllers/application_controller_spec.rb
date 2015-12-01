require 'rails_helper'

describe ApplicationController do
  let(:user) { create(:user) }

  controller do
    def index
      render nothing: true, status: 200
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

  describe 'forced onboarding' do
    let(:user) { create(:user, onboarded: onboarded) }

    describe 'when authenticated and onboarded' do
      let(:onboarded) { true }

      it 'should not redirect' do
        allow(controller).to receive(:current_user).and_return(user)
        get 'index'
        expect(response.status).to eq(200)
      end
    end

    describe 'when authenticated and NOT onboarded' do
      let(:onboarded) { false }

      it 'should redirect to onboarding' do
        pending 'todo'
        allow(controller).to receive(:current_user).and_return(user)
        get 'index'
        expect(response).to redirect_to(:onboarding)
      end
    end

    describe 'when not authenticated' do
      it 'should not redirect' do
        allow(controller).to receive(:current_user).and_return(nil)
        get 'index'
        expect(response.status).to eq(200)
      end
    end

    describe 'when already at onboarding route' do
      let(:onboarded) { false }

      it 'should not redirect' do
        allow(controller).to receive(:current_user).and_return(user)
        subject { get :onboarding }
        expect(response.status).to eq(200)
      end
    end
  end
end
