# frozen_string_literal: true

require 'rails_helper'

describe ReportsController, type: :request do
  let(:user) { create(:user) }
  let(:course) { create(:course, id: 1, slug: 'foo/bar_(baz)') }
  let(:campaign) { create(:campaign) }

  before do
    campaign.courses << course
  end

  after do
    FileUtils.remove_dir('public/system/analytics')
  end

  describe 'authenticated course CSV endpoints' do
    before do
      login_as user
    end

    it '#course_csv returns a CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
      get '/course_csv', params: { course: course.slug }
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include(course.title)
    end

    it '#course_uploads_csv returns a CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_uploads_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
      get '/course_uploads_csv', params: { course: course.slug }
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('filename')
    end

    it '#course_students_csv returns a CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_students_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
      get '/course_students_csv', params: { course: course.slug }
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('username')
    end

    it '#course_articles_csv returns a CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_articles_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
      get '/course_articles_csv', params: { course: course.slug }
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('pageviews_link')
    end

    it '#course_wikidata_csv returns a CSV' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/course_wikidata_csv', params: { course: course.slug }
      expect(response.body).to include('file is being generated')
      get '/course_wikidata_csv', params: { course: course.slug }
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('total revisions')
    end
  end

  describe '#campaign_students_csv' do
    let(:student) { create(:user) }

    before do
      login_as student
      create(:courses_user, course_id: course.id, user_id: student.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of student usernames' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/students", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/students", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(student.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of student usernames with course slugs' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/students", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/students", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(student.username)
        expect(csv).to include(course.slug)
      end
    end
  end

  describe '#campaign_instructors_csv' do
    let(:instructor) { create(:user) }

    before do
      login_as instructor
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    context 'without "course" option' do
      let(:request_params) { { slug: campaign.slug, format: :csv } }

      it 'returns a csv of instructor usernames' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        follow_redirect!
        expect(response.body).to include(instructor.username)
      end
    end

    context 'with "course" option' do
      let(:request_params) { { slug: campaign.slug, course: true, format: :csv } }

      it 'returns a csv of instructor usernames with course slugs' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        expect(response.body).to include('file is being generated')
        get "/campaigns/#{campaign.slug}/instructors", params: request_params
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include(instructor.username)
        expect(csv).to include(course.slug)
      end
    end
  end

  describe '#campaign_courses_csv' do
    let(:instructor) { create(:user) }
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      login_as instructor
      create(:courses_user, course_id: course.id, user_id: instructor.id,
                            role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    end

    it 'returns a csv of course data' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include(course.slug)
      expect(csv).to include(course.title)
      expect(csv).to include(course.school)
    end

    it 'cleans up the files afterwards' do
      # This normally happens long afterwards, but in test mode
      # sidekiq will execute all jobs immediately, so the file
      # will be created and immediately deleted.
      expect(CsvCleanupWorker).to receive(:perform_at).and_call_original
      get "/campaigns/#{campaign.slug}/courses", params: request_params
      expect(response.body).to include('file is being generated')
    end
  end

  describe 'CSV actions' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:another_course) { create(:course, home_wiki: wikidata, slug: 'campaign/acourse') }
    let(:article) { create(:article) }
    let(:user) { create(:user) }
    let!(:act) do
      create(:article_course_timeslice, course:, article:, user_ids: [user.id], revision_count: 12,
      start: course.start, end: course.start + 1.day)
    end
    let!(:course_stats) do
      create(:course_stats, stats_hash: { 'www.wikidata.org' => {
               'claims created' => 12, 'other updates' => 1, 'unknown' => 1
             } },
             course:)
    end
    let(:request_params) { { slug: campaign.slug, format: :csv } }

    before do
      stub_wiki_validation
      login_as(user)
      campaign.courses << another_course
      create(:courses_user, course:, user:)
    end

    it 'return a csv of article data' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/articles_csv", params: request_params
      get "/campaigns/#{campaign.slug}/articles_csv", params: request_params
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include(course.slug)
      expect(csv).to include(article.title)
    end

    it 'returns a csv of wikidata' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get "/campaigns/#{campaign.slug}/wikidata"
      get "/campaigns/#{campaign.slug}/wikidata"
      follow_redirect!
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('course name,claims created')
    end
  end
end
