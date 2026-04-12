# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/personal_data/personal_data_csv_builder"

describe PersonalData::PersonalDataCsvBuilder, type: :request do
  let(:user) do
    create(:user,
           username: 'Sage the Rage',
           real_name: 'Sage Ross',
           email: 'sage@example.com',
           created_at: '2025-01-28 16:04:05 UTC',
           updated_at: '2025-01-28 16:04:05 UTC',
           locale: 'en',
           first_login: '2025-01-27 16:04:05 UTC')
  end
  let(:course) { create(:course) }
  let(:campaign) { create(:campaign) }

  before do
    create(:user_profile, user_id: user.id, bio: 'My bio',
                          location: 'NYC', institution: 'Wiki Ed')
    courses_user = create(:courses_user, user_id: user.id, course_id: course.id, role: 0)
    create(:assignment, user_id: user.id, course_id: course.id,
                        article_title: 'Siderocalin', role: 0)
    # Reload so the association picks up the assignment
    courses_user.reload
    create(:campaigns_user, user_id: user.id, campaign_id: campaign.id)
  end

  it 'logs in as the user, downloads personal data in CSV, and checks its content' do
    login_as(user)

    csv_content = described_class.new(user).generate_csv

    csv_lines = csv_content.split("\n")

    expect(csv_lines.count).to be >= 2

    # User info
    expect(csv_lines[0]).to include(
      'Username',
      'Real Name',
      'Email',
      'Created At',
      'Updated At',
      'Locale',
      'First Login'
    )

    expect(csv_lines[1]).to include(
      'Sage the Rage',
      'Sage Ross',
      'sage@example.com',
      '2025-01-28 16:04:05 UTC',
      '2025-01-28 16:04:05 UTC',
      'en',
      '2025-01-27 16:04:05 UTC'
    )

    # User profile info
    expect(csv_content).to include('Bio', 'Location', 'Institution')
    expect(csv_content).to include('My bio', 'NYC', 'Wiki Ed')

    # Course info
    expect(csv_content).to include('Course', 'Role', 'Character Sum MS')
    expect(csv_content).to include(course.slug)

    # Assignment info
    expect(csv_content).to include('Assignment Title', 'Assignment URL', 'Sandbox URL')
    expect(csv_content).to include('Siderocalin')

    # Campaign info
    expect(csv_content).to include('Campaign', 'Joined At')
    expect(csv_content).to include(campaign.slug)
  end
end
