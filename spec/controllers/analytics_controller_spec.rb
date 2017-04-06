# frozen_string_literal: true
require 'rails_helper'

describe AnalyticsController do
  let(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    create(:campaign, id: 1, title: 'First Campaign')
    create(:campaign, id: 2, title: 'Second Campaign')
    create(:course, id: 1, start: 1.year.ago, end: 1.day.from_now)
    create(:campaigns_course, course_id: 1, campaign_id: 1)
  end

  describe '#index' do
    it 'renders' do
      get 'index'
      expect(response.status).to eq(200)
    end
  end

  describe '#results' do
    it 'returns a monthly report' do
      post 'results', params: { monthly_report: true }
      expect(response.status).to eq(200)
    end

    it 'returns campaign statistics' do
      post 'results', params: { campaign_stats: true }
      expect(response.status).to eq(200)
    end

    it 'return campaign intersection statistics' do
      post 'results', params: { campaign_intersection: true,
                                campaign_1: { id: 1 },
                                campaign_2: { id: 2 } }
      expect(response.status).to eq(200)
    end
  end

  describe '#ungreeted' do
    before do
      create(:courses_user, user_id: user.id, course_id: 1,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:courses_user, user_id: user.id, course_id: 1,
                            role: CoursesUsers::Roles::WIKI_ED_STAFF_ROLE)
    end
    it 'returns a CSV' do
      allow(controller).to receive(:current_user).and_return(user)
      get 'ungreeted', params: { format: 'csv' }
      expect(response.body).to have_content(user.username)
    end
  end
end
