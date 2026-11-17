# frozen_string_literal: true

require 'rails_helper'

describe 'User tokens in JSON', type: :request do
  let(:admin) { create(:admin, username: 'PlainAdmin') }
  let!(:super_admin) do
    create(:super_admin, username: 'Super',
                         wiki_token: 'SUPER-TOKEN', wiki_secret: 'SUPER-SECRET')
  end
  let!(:special_user) do
    create(:user, username: 'Special', wiki_token: 'SPECIAL-TOKEN', wiki_secret: 'SPECIAL-SECRET')
  end

  it 'are left out of a user inside a rendered hash' do
    json = { user: super_admin }.to_json
    expect(json).not_to include('SUPER-TOKEN')
    expect(json).not_to include('SUPER-SECRET')
  end

  it 'are left out of the admin list' do
    login_as admin
    get '/settings/all_admins', params: { format: :json }
    expect(response.body).to include('Super')
    expect(response.body).not_to include('SUPER-TOKEN')
    expect(response.body).not_to include('SUPER-SECRET')
  end

  it 'are left out of the special users list' do
    SpecialUsers.set_user('classroom_program_manager', special_user.username)
    login_as admin
    get '/settings/special_users', params: { format: :json }
    expect(response.body).to include('Special')
    expect(response.body).not_to include('SPECIAL-TOKEN')
    expect(response.body).not_to include('SPECIAL-SECRET')
  end
end
