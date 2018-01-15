# frozen_string_literal: true

require 'rails_helper'

describe SettingsController do
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
    end # not an admin

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
    end # already_admin
  end # upgrade_admin

  #   ## NEW ACTION!
  describe 'when attempting to remove an admin' do
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
    end # is an admin

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
    end # already_instructor

    context 'when request is not json' do
      before do
        @format_type = :html
      end
    end
  end
end