require 'rails_helper'

describe AnalyticsController do
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    create(:cohort, id: 1, slug: 'first_cohort')
    create(:cohort, id: 2, slug: 'second_cohort')
    create(:course, id: 1, start: 1.year.ago, end: Time.zone.today)
    create(:cohorts_course, course_id: 1, cohort_id: 1)
  end

  describe '#index' do
    it 'renders' do
      get 'index'
      expect(response.status).to eq(200)
    end
  end

  describe '#results' do
    it 'returns a monthly report' do
      post 'results', monthly_report: true
      expect(response.status).to eq(200)
    end

    it 'returns cohort statistics' do
      post 'results', cohort_stats: true
      expect(response.status).to eq(200)
    end

    it 'return cohort intersection statistics' do
      post 'results', cohort_intersection: true,
                      cohort_1: { id: 1 },
                      cohort_2: { id: 2 }
      expect(response.status).to eq(200)
    end
  end

  describe '#training_completion' do
    it 'renders' do
      post 'training_completion'
      expect(response.status).to eq(200)
    end
  end
end
