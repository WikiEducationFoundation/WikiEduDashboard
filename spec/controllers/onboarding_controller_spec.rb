require 'rails_helper'

describe OnboardingController do
  let(:user) { create(:user, onboarded: onboarded) }

  describe 'onboarding route' do

    describe 'when not authenticated' do
      let(:onboarded) { false }

      it 'should redirect to root_path' do
        allow(controller).to receive(:current_user).and_return(nil)
        allow(controller).to receive(:user_signed_in?).and_return(false)
        get 'index'
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'when already onboarded' do
      let(:onboarded) { true }

      it 'should redirect to root_path' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        get 'index'
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'when not onboarded' do
      let(:onboarded) { false }

      it 'should not redirect' do
        allow(controller).to receive(:current_user).and_return(user)
        allow(controller).to receive(:user_signed_in?).and_return(true)
        get 'index'
        expect(response.status).to eq(200)
      end
    end
  end
end
