# frozen_string_literal: true

require 'rails_helper'

describe ReportCardsController, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:campaign) { create(:campaign, title: 'Scholars and Scientists 2025-26', slug: 'ss_2025_26') }
  let(:course) do
    create(:course, type: 'FellowsCohort', slug: 'S/course', title: 'Report card course',
                    start: 200.days.ago, end: 120.days.ago)
  end
  let(:student) { create(:user, username: 'student') }

  before do
    campaign.courses << course
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:retention_stat, course:, user: student, sessions_during: 3, days_to_return: 10,
                            sessions_after: 2, edits_60_90: 6)
  end

  context 'as an admin' do
    before { login_as admin }

    it 'lists the campaigns that have report card data' do
      create(:campaign, title: 'Empty campaign', slug: 'empty')
      get '/report_cards'
      expect(response.body).to include('Scholars and Scientists 2025-26')
      expect(response.body).not_to include('Empty campaign')
    end

    it 'renders the report card for a campaign' do
      get "/report_cards/#{campaign.slug}"
      expect(response.body).to include('Report card course')
      expect(response.body).to include('Participants who edited in 30 days after course')
    end

    it 'downloads the report card as CSV' do
      get "/report_cards/#{campaign.slug}.csv"
      expect(response.content_type).to include('text/csv')
      expect(response.body).to include('Report card course')
    end

    it 'is not found for an unknown campaign' do
      get '/report_cards/no_such_campaign'
      expect(response).to have_http_status(:not_found)
    end

    it 'does not exist on the Programs & Events Dashboard' do
      allow(Features).to receive(:wiki_ed?).and_return(false)
      get '/report_cards'
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as a non-admin' do
    before { login_as user }

    it 'is not authorized' do
      get "/report_cards/#{campaign.slug}"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed out' do
    it 'is not authorized' do
      get '/report_cards'
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
