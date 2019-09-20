# frozen_string_literal: true

require 'rails_helper'

describe PersonalDataController, type: :request do
  let(:user) { create(:user, username: 'Sage the Rage', real_name: 'Sage Ross') }

  it 'returns personal data about the current user' do
    login_as(user)
    get '/download_personal_data.json'
    expect(response.body).to include('Sage the Rage')
  end
end
