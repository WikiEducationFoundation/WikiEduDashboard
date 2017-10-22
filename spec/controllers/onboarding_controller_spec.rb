# frozen_string_literal: true

require 'rails_helper'

describe OnboardingController do
  before { stub_list_users_query }
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

  describe '#onboard' do
    let(:user) { create(:user, onboarded: false) }

    before do
      login_as(user, scope: user)
      allow(controller).to receive(:current_user).and_return(user)
    end

    it 'should onboard with valid params' do
      params = { real_name: 'Name', email: 'email@email.org', instructor: false }
      put 'onboard', params: params
      expect(response.status).to eq(204)
      expect(user.reload.onboarded).to eq(true)
      expect(user.real_name).to eq('Name')
      expect(user.email).to eq('email@email.org')
    end

    it 'should not onboard with invalid params' do
      expect { put 'onboard', params: { real_name: 'Name', email: 'email@email.org' } }
        .to raise_error ActionController::ParameterMissing
    end

    it 'should remain an admin regardless of instructor param' do
      user.update_attributes(permissions: User::Permissions::ADMIN, onboarded: false)
      put 'onboard', params: { real_name: 'Name', email: 'email@email.org', instructor: true }
      expect(response.status).to eq(204)
      expect(user.reload.onboarded).to eq(true)
      expect(user.permissions).to eq(User::Permissions::ADMIN)
    end

    it 'should strip name field of excessive whitespace' do
      params = { real_name: " Name  \n Surname ", email: 'email@email.org', instructor: false }
      put 'onboard', params: params
      expect(user.real_name).to eq('Name Surname')
    end
  end
end
