# frozen_string_literal: true

require 'rails_helper'
require 'pry'
describe SettingsController do
  describe '#index' do
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }
    let(:super_admin) { create(:admin, username: 'Rage') }
    let!(:special_user) { create( :special_users, value: { super_admin: super_admin.username }) }

    it 'renders for super admins' do
      allow(controller).to receive(:current_user).and_return(super_admin)
      # binding.pry
      get :index
      expect(response.status).to eq(200)
    end

    it 'returns a 401 if the user is not an admin' do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
      expect(response.status).to eq(401)
      # expect(response).to redirect_to(root_path)
    end

    it 'redirects for non-super admins' do
      allow(controller).to receive(:current_user).and_return(admin)
      get :index
      expect(response).to redirect_to(admin_index_path)
    end
  end

  describe '#update' do
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }
    let(:super_admin) { create(:admin, username: 'Rage') }
    let!(:special_user) { create( :special_users, value: { super_admin: super_admin.username }) }
    let(:users)  { {  "classroom_program_manager" => user.username,
                      "super_admin" => super_admin.username } }
    let(:new_setting) { "" }
    let(:new_setting_value) { "" }
    let(:setting_params) { { id: special_user.id,
                            setting:
                              { new_setting: new_setting,
                                setting_value: new_setting_value,
                                special_users: users }
                            } }
    it 'returns a 401 if the user is not an admin' do
      allow(controller).to receive(:current_user).and_return(user)
      post :update, params: setting_params
      expect(response.status).to eq(401)
    end

    it 'updates the settings if the user is super admins (no empty settings)' do
      allow(controller).to receive(:current_user).and_return(super_admin)
      post :update, params: setting_params
      expect(response.status).to eq(302) # redirect to /settings
      expect(Setting.find(special_user.id).value).to eq(users)
    end

    it 'adds new setting if it legal' do
      allow(controller).to receive(:current_user).and_return(super_admin)
      new_setting = "test key"
      new_setting_value = "test value"
      users[new_setting] = new_setting_value
      post :update, params: setting_params
      expect(response.status).to eq(302) # redirect to /settings
      expect(Setting.find(special_user.id).value).to eq(users)
    end

    it 'adds nothing if setting already exists' do
      allow(controller).to receive(:current_user).and_return(super_admin)
      new_setting = "super admin"
      new_setting_value = "test value"
      post :update, params: setting_params
      expect(response.status).to eq(302) # redirect to /settings
      expect(Setting.find_by_id(special_user.id).value).to eq(users)
    end
  end

  describe '#delete' do
    let(:admin) { create(:admin) }
    let(:user) { create(:user) }
    let(:super_admin) { create(:admin, username: 'Rage') }
    let(:users)  { {  classroom_program_manager: super_admin.username,
                      super_admin: super_admin.username } }
    let!(:special_user) { create(:special_users, value: users) }
    let(:new_setting) { "" }
    let(:new_setting_value) { "" }
    let(:setting_params) { { id: special_user.id,
                              "q" => users.first.first
                            } }

    it 'returns a 401 if the user is not an admin and not an organizer of the campaign' do
      allow(controller).to receive(:current_user).and_return(user)
      delete :destroy, params: setting_params
      expect(response.status).to eq(401)
      users.delete(setting_params["q"])
      expect(Setting.find_by_id(special_user.id).value).not_to eq(users)
    end

    it 'removes the given setting from the settings list if the current user is the super admin' do
      # binding.pry
      allow(controller).to receive(:current_user).and_return(super_admin)
      delete :destroy, params: setting_params
      expect(response.status).to eq(302)
      users.delete(setting_params["q"])
      expect(Setting.find_by_id(special_user.id).value).to eq(users)
    end
  end
end
