# frozen_string_literal: true

require 'rails_helper'

describe OnboardingController, type: :request do
  before { stub_list_users_query }

  let(:user) { create(:user, onboarded:) }

  describe 'onboarding route' do
    describe 'when not authenticated' do
      let(:onboarded) { false }

      it 'redirects to root_path' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(false)
        get '/onboarding'
        expect(response).to redirect_to(root_path)
      end
    end

    describe 'when not onboarded' do
      let(:onboarded) { false }

      it 'does not redirect' do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        allow_any_instance_of(ApplicationController).to receive(:user_signed_in?).and_return(true)
        get '/onboarding'
        expect(response.status).to eq(200)
      end
    end
  end

  describe '#onboard' do
    let(:user) { create(:user, onboarded: false) }

    before do
      login_as(user, scope: user)
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    it 'onboards with valid params' do
      params = { real_name: 'Name', email: 'email@email.org', instructor: false }
      put '/onboarding/onboard', params: params
      expect(response.status).to eq(204)
      expect(user.reload.onboarded).to eq(true)
      expect(user.real_name).to eq('Name')
      expect(user.email).to eq('email@email.org')
    end

    it 'does not onboard with invalid params' do
      expect { put '/onboarding/onboard', params: { real_name: 'Name', email: 'email@email.org' } }
        .to raise_error ActionController::ParameterMissing
    end

    it 'remains an admin regardless of instructor param' do
      user.update(permissions: User::Permissions::ADMIN, onboarded: false)
      params = { real_name: 'Name', email: 'email@email.org', instructor: true }
      put '/onboarding/onboard', params: params
      expect(response.status).to eq(204)
      expect(user.reload.onboarded).to eq(true)
      expect(user.permissions).to eq(User::Permissions::ADMIN)
    end

    it 'strips name field of excessive whitespace' do
      params = { real_name: " Name  \n Surname ", email: 'email@email.org', instructor: false }
      put '/onboarding/onboard', params: params
      expect(user.real_name).to eq('Name Surname')
    end
  end

  describe '#supplementary' do
    let(:user) { create(:user, onboarded: false, username: 'JonSnow') }

    it 'creates an alert for instructor' do
      params = { user_name: user.username, heardFrom: 'From Nights Watch' }
      put '/onboarding/supplementary', params: params
      expect(response.status).to eq(204)
      expect(Alert.exists?(user_id: user.id, type: 'OnboardingAlert')).to eq(true)
    end

    it 'includes referral information if sent' do
      params = {
        user_name: user.username,
        heardFrom: 'From Nights Watch',
        referralDetails: 'Jeor Mormont'
      }
      put '/onboarding/supplementary', params: params
      expect(response.status).to eq(204)
      alert = Alert.where(user_id: user.id, type: 'OnboardingAlert').first
      expect(alert.message).to include('Jeor Mormont')
    end

    it 'stores information in the details field' do
      params = {
        user_name: user.username,
        heardFrom: 'From Nights Watch',
        referralDetails: 'Jeor Mormont'
      }
      put '/onboarding/supplementary', params: params
      expect(response.status).to eq(204)
      alert = Alert.where(user_id: user.id, type: 'OnboardingAlert').first
      expect(alert.reload.details['heard_from']['answer']).to eq('From Nights Watch')
      expect(alert.reload.details['heard_from']['additional']).to eq('Jeor Mormont')
    end
  end
end
