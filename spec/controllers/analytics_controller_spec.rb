require 'rails_helper'

describe AnalyticsController do
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    create(:cohort, id: 1, slug: 'first_cohort')
    create(:cohort, id: 2, slug: 'second_cohort')
  end

  describe '#index' do
    it 'should render' do
      get 'index'
      expect(response.status).to eq(200)
    end
  end

  describe '#results' do
    it 'should return a monthly report' do
      post 'results', monthly_report: true
      expect(response.status).to eq(200)
    end

    it 'should return a cohort statistics' do
      post 'results', cohort_stats: true
      expect(response.status).to eq(200)
    end

    it 'should return a cohort intersection statistics' do
      post 'results', cohort_intersection: true,
                      cohort_1: { id: 1 },
                      cohort_2: { id: 2 }
      expect(response.status).to eq(200)
    end
  end
end
