# frozen_string_literal: true

require 'rails_helper'

describe SettingsController do
  describe '#index' do
    it 'renders for super admins' do
      super_admin = create(:super_admin)
      allow(controller).to receive(:current_user).and_return(super_admin)
      get :index
      expect(response.status).to eq(200)
    end

    %i[admin instructor user].each do |role|
      it "redirects for role of #{role}" do
        user = create(role)
        allow(controller).to receive(:current_user).and_return(user)
        get :index
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#all_admins' do
    before do
      # create an admin and super admin
      create(:user)
      create(:admin)
      @super_admin = create(:super_admin)
    end

    context 'when request is json' do
      before do
        allow(controller).to receive(:current_user).and_return(@super_admin)
        get :all_admins, format: :json
      end

      it 'returns all admin users' do
        expect(JSON.parse(response.body)['admins'].length).to be(2)
      end

      it 'returns 200 ok' do
        expect(response.status).to be(200)
      end
    end

    context 'when request is not json' do
      before do
        allow(controller).to receive(:current_user).and_return(@super_admin)
        get :all_admins
      end

      it 'returns 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'when the user is not permitted' do
      before do
        allow(controller).to receive(:current_user).and_return(create(:user, username: 'reg_user'))
        get :all_admins, format: :json
      end

      it 'denies access' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe '#upgrade_admin' do
    before do
      super_admin = create(:super_admin)
      allow(controller).to receive(:current_user).and_return(super_admin)
      @action = :upgrade_admin
      @format_type = :json
    end

    let(:post_params) do
      params = { user: { username: @user.username } }
      post @action, params: params, format: @format_type
    end

    context 'user is not an admin' do
      before do
        @user = create(:user)
        post_params
      end

      it 'turns user into admin' do
        expect(@user.reload.admin?).to be(true)
      end

      it 'returns http 200' do
        expect(response.status).to be(200)
      end

      it 'returns the right message' do
        expect(response.body).to have_content("#{@user.username} elevated to admin.")
      end
    end

    context 'user is already an admin' do
      before do
        @user = create(:admin)
        post_params
      end

      it 'user remains admin' do
        expect(@user.reload.admin?).to be true
      end

      it 'returns http 422' do
        expect(response.status).to be(422)
      end

      it 'returns the right message' do
        expect(response.body).to have_content("#{@user.username} is already an admin!")
      end
    end

    context 'when the user does not exist' do
      before do
        @user = build(:user)
        post_params
      end

      it 'returns a 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  describe '#downgrade_admin' do
    before do
      @action = :downgrade_admin
      @format_type = :json
      super_admin = create(:super_admin)
      allow(controller).to receive(:current_user).and_return(super_admin)
    end

    let(:post_params) do
      params = { user: { username: @user.username } }
      post @action, params: params, format: @format_type
    end

    context 'user is an admin' do
      before do
        @user = create(:admin)
        post_params
      end

      it 'turns admin into instructor' do
        expect(@user.reload.instructor_permissions?).to be true
      end

      it 'returns http 200' do
        expect(response.status).to be(200)
      end

      it 'returns the right message' do
        expect(response.body).to have_content("#{@user.username} changed to instructor.")
      end
    end

    context 'user is already an instructor' do
      before do
        @user = create(:instructor)
        post_params
      end

      it 'user remains instructor' do
        expect(@user.reload.instructor_permissions?).to be true
      end

      it 'returns http 422' do
        expect(response.status).to be(422)
      end

      it 'returns the right message' do
        expect(response.body).to have_content("#{@user.username} is already an instructor!")
      end
    end

    context 'user is super_admin' do
      before do
        @user = create(:super_admin, username: 'tryandrevokeme')
        post_params
      end

      it 'disallows revocation' do
        expect(@user.reload.super_admin?).to be true
      end

      it 'returns http 422' do
        expect(response.status).to be(422)
      end

      it 'returns the right message' do
        expect(response.body).to have_content("Can't revoke admin status from a super admin")
      end
    end

    context 'request is not json' do
      before do
        @format_type = :html
      end
    end
  end

  describe '#upgrade_special_user' do
    before do
      super_admin = create(:super_admin)
      allow(controller).to receive(:current_user).and_return(super_admin)
      @action = :upgrade_special_user
      @format_type = :json
    end

    let(:post_params) do
      params = { special_user: { username: @user.username, position: 'communications_manager' } }
      post @action, params: params, format: @format_type
    end

    let(:post_invalid_position_params) do
      params = { special_user: { username: @user.username, position: 'apositionhasnoname' } }
      post @action, params: params, format: @format_type
    end

    context 'user is not an communications_manager' do
      before do
        @position = 'communications_manager'
        @user = create(:user)
        post_params
      end

      it 'turns user into admin' do
        expect(SpecialUsers.is?(@user, @position)).to be(true)
      end

      it 'returns http 200' do
        expect(response.status).to be(200)
      end

      it 'returns the right message' do
        expect(response.body).to have_content(
          I18n.t(
            'settings.special_users.new.elevate_success',
            username: @user.username,
            position: @position
          )
        )
      end
    end

    context 'user is already communications_manager' do
      before do
        @user = create(:user)
        @position = 'communications_manager'
        Setting.set_special_user(@position, @user.username)
        post_params
      end

      it 'user remains communications_manager' do
        expect(SpecialUsers.is?(@user, @position)).to be(true)
      end

      it 'returns http 422' do
        expect(response.status).to be(422)
      end

      it 'returns the right message' do
        expect(response.body).to have_content(
          I18n.t(
            'settings.special_users.new.already_is',
            username: @user.username,
            position: @position
          )
        )
      end
    end

    context 'when the user does not exist' do
      before do
        @user = build(:user)
        post_params
      end

      it 'returns a 404' do
        expect(response.status).to eq(404)
      end
    end

    context 'when the position is invalid' do
      before do
        @user = create(:user)
        post_invalid_position_params
      end

      it 'returns position is invalid' do
        expect(response.body).to have_content('position is invalid')
      end
    end
  end

  describe '#downgrade_special_user' do
    before do
      @action = :downgrade_special_user
      @format_type = :json
      super_admin = create(:super_admin)
      allow(controller).to receive(:current_user).and_return(super_admin)
    end

    let(:post_params) do
      params = { special_user: { username: @user.username, position: 'communications_manager' } }
      post @action, params: params, format: @format_type
    end

    context 'user is a communications_manager' do
      before do
        @user = create(:user)
        @position = 'communications_manager'
        Setting.set_special_user(@position, @user.username)
        post_params
      end

      it 'removes the user as communications_manager' do
        expect(SpecialUsers.is?(@user, @position)).to be false
      end

      it 'returns http 200' do
        expect(response.status).to be(200)
      end

      it 'returns the right message' do
        expect(response.body).to have_content(
          I18n.t(
            'settings.special_users.remove.demote_success',
            username: @user.username,
            position: @position
          )
        )
      end
    end

    context 'user is already just a user' do
      before do
        @user = create(:user)
        @position = 'communications_manager'
        post_params
      end

      it 'user remains a normal user' do
        expect(SpecialUsers.is?(@user, @position)).to be false
      end

      it 'returns http 422' do
        expect(response.status).to be(422)
      end

      it 'returns the right message' do
        expect(response.body).to have_content(
          I18n.t(
            'settings.special_users.new.already_is_not',
            username: @user.username,
            position: @position
          )
        )
      end
    end
  end
end
