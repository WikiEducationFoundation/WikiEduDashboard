# frozen_string_literal: true

require 'rails_helper'

describe 'Claim verification exercise', type: :request do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki)
  end
  let(:student) { create(:user, username: 'Otterfan', onboarded: true) }

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    login_as student
  end

  it 'shows the assigned claim, its source link, and a sandbox handoff link' do
    VerificationClaim.create!(wiki:, subject: 'Ecology',
                              sentence: 'Sea otters use rocks as tools.',
                              cite_text: 'Riedman 1990',
                              source_url: 'https://example.com/otters')
    get "/courses/#{course.slug}/verify_claim"
    expect(response.body).to include('Sea otters use rocks as tools.')
    expect(response.body).to include('https://example.com/otters')
    expect(response.body)
      .to include('en.wikipedia.org/wiki/User:Otterfan/Claim_verification_exercise')
  end

  it 'renders without error when the pool has no claim to assign' do
    get "/courses/#{course.slug}/verify_claim"
    expect(response).to have_http_status(:ok)
  end
end
