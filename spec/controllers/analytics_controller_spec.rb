# frozen_string_literal: true

require 'rails_helper'

class MockR
  def eval(_string)
    nil
  end

  def before_count
    15
  end

  def before_mean
    5.6
  end

  def after_mean
    50.9
  end
end

describe AnalyticsController do
  let(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    create(:campaign, id: 1, title: 'First Campaign')
    create(:campaign, id: 2, title: 'Second Campaign')
    create(:course, id: 1, start: 1.year.ago, end: 1.day.from_now)
    create(:campaigns_course, course_id: 1, campaign_id: 1)

    # We cheat here to skip actually running any R code,
    # since the output is very messy will depend on having specific R packages
    # installed.
    stub_const('R', MockR.new)
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

    it 'returns a structural completeness density plot' do
      post 'results', params: { ores_changes: true,
                                campaign: { id: 1 },
                                minimum_bytes: 0,
                                graph_type: 'density',
                                existing_only: true }
      expect(response.status).to eq(200)
    end

    it 'returns a structural completeness histogram plot' do
      post 'results', params: { ores_changes: true,
                                campaign: { id: 1 },
                                minimum_bytes: 1000,
                                graph_type: 'histogram',
                                minimum_improvement: 10,
                                existing_only: false }
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

  describe '#course_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }
    it 'returns a CSV' do
      get 'course_csv', params: { course: course.slug }
      expect(response.body).to have_content(course.slug)
    end
  end

  describe '#course_edits_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }
    it 'returns a CSV' do
      get 'course_edits_csv', params: { course: course.slug }
      expect(response.body).to have_content('revision_id')
    end
  end

  describe '#course_uploads_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }
    it 'returns a CSV' do
      get 'course_uploads_csv', params: { course: course.slug }
      expect(response.body).to have_content('filename')
    end
  end

  describe '#course_students_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }
    it 'returns a CSV' do
      get 'course_students_csv', params: { course: course.slug }
      expect(response.body).to have_content('username')
    end
  end

  describe '#course_articles_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }
    it 'returns a CSV' do
      get 'course_articles_csv', params: { course: course.slug }
      expect(response.body).to have_content('pageviews_link')
    end
  end

  describe '#usage' do
    render_views
    it 'renders the stats page' do
      get 'usage'
      expect(response.body).to have_content('Usage Stats')
    end
  end
end
