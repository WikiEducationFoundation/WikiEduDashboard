# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/personal_data/personal_data_csv_builder"

describe PersonalData::PersonalDataCsvBuilder, type: :request do
  let(:user) { create(:user, username: 'Sage the Rage', real_name: 'Sage Ross', email: 'sage@example.com', created_at: '2025-01-28 16:04:05 UTC', updated_at: '2025-01-28 16:04:05 UTC', locale: 'en', first_login: '2025-01-27 16:04:05 UTC') }

  it 'logs in as the user, downloads personal data in CSV, and checks its content' do
    login_as(user)

    csv_content = PersonalData::PersonalDataCsvBuilder.new(user).generate_csv

    csv_lines = csv_content.split("\n")

    expect(csv_lines.count).to be >= 2

    expect(csv_lines[0]).to include('Username', 'Real Name', 'Email', 'Created At', 'Updated At', 'Locale', 'First Login')

    expect(csv_lines[1]).to include('Sage the Rage', 'Sage Ross', 'sage@example.com', '2025-01-28 16:04:05 UTC', '2025-01-28 16:04:05 UTC', 'en', '2025-01-27 16:04:05 UTC')
  end
end
