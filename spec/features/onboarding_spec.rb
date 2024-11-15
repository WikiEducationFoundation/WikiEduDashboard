# frozen_string_literal: true

require 'rails_helper'

describe 'onboarding', type: :feature, js: true do
  before { stub_list_users_query }

  let(:user) { create(:user, onboarded:, real_name: 'test', email: 'email@email.com') }

  describe 'onboarding redirect checks' do
    describe 'when not logged in' do
      let(:onboarded) { false }

      it 'is not able to access onboarding' do
        visit onboarding_path
        expect(page).to have_current_path(root_path)
      end
    end

    describe 'when logged in and not onboarded' do
      let(:onboarded) { false }

      before do
        login_as(user, scope: :user)
      end

      it 'is able to access onboarding' do
        visit onboarding_path
        expect(page).to have_content 'excited'
      end

      it 'is not able to access other parts of the app' do
        visit explore_path
        expect(page).to have_current_path(onboarding_path, ignore_query: true)
      end

      it 'is able to log out' do
        visit destroy_user_session_path
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe 'onboarding forms' do
    let(:onboarded) { false }

    before do
      login_as(user, scope: :user)
    end

    it 'pre-populates' do
      visit onboarding_path
      find('.intro .button').click
      expect(find('input[name=name]').value).to eq 'test'
      expect(find('input[name=email]').value).to eq 'email@email.com'
    end

    it 'updates user when submitted' do
      visit onboarding_path
      find('.intro .button').click
      find('input[type=radio][value=true]').click
      find('form button[type=submit]').click
      expect(page).to have_content 'How did you hear about us?'
      expect(user.reload.onboarded).to eq true
      expect(user.permissions).to eq User::Permissions::INSTRUCTOR
    end

    it 'updates real name for enrolled courses' do
      course = create(:course)
      enrollment = create(:courses_user, course:, user:, real_name: 'Old Name')
      visit onboarding_path
      find('.intro .button').click
      fill_in 'name', with: 'New Name'
      find('form button[type=submit]').click
      expect(page).to have_content 'Permissions'
      expect(enrollment.reload.real_name).to eq('New Name')
    end
  end

  describe 'onboarding supplement' do
    let(:onboarded) { false }

    before do
      login_as(user, scope: :user)
    end

    it 'goes to supplementary' do
      visit onboarding_path
      find('.intro .button').click
      find('input[type=radio][value=true]').click
      find('form button[type=submit]').click
      page.assert_selector('form#supplementary')
      find('input[type="radio"][value="web"]').click
      click_button 'Submit'
    end

    it 'is able to provide additional referral details' do
      visit onboarding_path
      find('.intro .button').click
      find('input[type=radio][value=true]').click
      find('form button[type=submit]').click
      page.assert_selector('form#supplementary')
      find('input[type="radio"][value="association-or-conference"]').click
      fill_in 'referralDetails', with: 'Conference Name'
      click_button 'Submit'
    end
  end
end
