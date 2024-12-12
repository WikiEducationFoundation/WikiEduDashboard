# frozen_string_literal: true

require 'rails_helper'

describe AnalyticsController, type: :request do
  let(:user) { create(:user) }

  before do
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(nil)
    create(:campaign, id: 1, title: 'First Campaign')
    create(:campaign, id: 2, title: 'Second Campaign')
    create(:course, id: 1, start: 1.year.ago, end: 1.day.from_now)
    create(:campaigns_course, course_id: 1, campaign_id: 1)
  end

  describe '#index' do
    it 'renders' do
      get '/analytics'
      expect(response.status).to eq(200)
    end
  end

  describe '#results' do
    it 'returns a monthly report' do
      post '/analytics', params: { monthly_report: true }
      expect(response.status).to eq(200)
    end

    it 'returns campaign statistics' do
      post '/analytics', params: { campaign_stats: true }
      expect(response.status).to eq(200)
    end

    it 'return campaign intersection statistics' do
      post '/analytics', params: { campaign_intersection: true,
                                campaign_1: { id: 1 },
                                campaign_2: { id: 2 } }
      expect(response.status).to eq(200)
    end

    it 'returns a structural completeness density plot' do
      post '/analytics', params: { ores_changes: true,
                                campaign: { id: 1 },
                                minimum_bytes: 0,
                                graph_type: 'density',
                                existing_only: true }
      expect(response.status).to eq(200)
    end

    it 'returns a structural completeness histogram plot' do
      post '/analytics', params: { ores_changes: true,
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
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      get '/ungreeted', params: { format: 'csv' }
      expect(response.body).to include(user.username)
    end
  end

  describe '#course_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }

    it 'returns a CSV' do
      get '/course_csv', params: { course: course.slug }
      expect(response.body).to include(course.slug)
    end
  end

  describe '#course_uploads_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }

    it 'returns a CSV' do
      get '/course_uploads_csv', params: { course: course.slug }
      expect(response.body).to include('filename')
    end
  end

  describe '#course_students_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }

    it 'returns a CSV' do
      get '/course_students_csv', params: { course: course.slug }
      expect(response.body).to include('username')
    end
  end

  describe '#course_articles_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }

    it 'returns a CSV' do
      get '/course_articles_csv', params: { course: course.slug }
      expect(response.body).to include('pageviews_link')
    end
  end

  describe '#course_revisions_csv' do
    let(:course) { create(:course, slug: 'foo/bar_(baz)') }

    it 'returns a CSV' do
      get '/course_revisions_csv', params: { course: course.slug }
      expect(response.body).to include('references_added')
    end
  end

  describe '#course_wikidata_csv' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) { create(:course, slug: 'foo/bar_(baz)', home_wiki: wikidata) }

    before do
      stub_wiki_validation
      UpdateWikidataStats.new(course)
    end

    it 'returns a CSV' do
      get '/course_wikidata_csv', params: { course: course.slug }
      expect(response.body).to include('total revisions')
    end
  end

  describe '#all_courses_csv' do
    it 'returns a CSV' do
      get '/all_courses_csv'
      expect(response.body).to include('home_wiki')
    end
  end

  describe '#usage' do
    it 'renders the stats page' do
      get '/usage'
      expect(response.body).to include('Usage Stats')
    end
  end

  describe '#all_courses' do
    it 'returns JSON data about courses' do
      get '/all_courses.json'
      expect(JSON.parse(response.body)).to be_a(Hash)
      expect(response.body).to include(Course.first.slug)
    end
  end

  describe '#all_campaigns' do
    it 'returns JSON data about campaigns' do
      get '/all_campaigns.json'
      expect(JSON.parse(response.body)).to be_a(Hash)
      expect(response.body).to include(Campaign.first.slug)
    end
  end
end
