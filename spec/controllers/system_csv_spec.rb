# frozen_string_literal: true

require 'rails_helper'

describe ReportsController, '#system_csv', type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:en_wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }

  let!(:course) do
    create(:course, slug: 'school/test_course_(term)',
                    title: 'Test Course',
                    type: 'ClassroomProgramCourse',
                    home_wiki: en_wiki,
                    start: 1.month.ago,
                    end: 1.month.from_now)
  end

  before do
    stub_wiki_validation
  end

  after do
    FileUtils.remove_dir('public/system/analytics') if File.directory?('public/system/analytics')
  end

  context 'when not signed in' do
    it 'returns 401 unauthorized' do
      get '/system_csv'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in as a non-admin' do
    before { login_as user }

    it 'returns 401 unauthorized' do
      get '/system_csv'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in as an admin' do
    before { login_as admin }

    describe 'without filters' do
      it 'enqueues a background job and returns generation message' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv'
        expect(response.body).to include('file is being generated')
      end

      it 'returns CSV on second request after generation' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv'
        expect(response.body).to include('file is being generated')

        get '/system_csv'
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('course_slug')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with campaign_slug filter' do
      let(:campaign) { create(:campaign, slug: 'test_campaign') }

      before { campaign.courses << course }

      it 'generates CSV filtered by campaign' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { campaign_slug: 'test_campaign' }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: { campaign_slug: 'test_campaign' }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with course_type filter' do
      it 'generates CSV filtered by course type' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { course_type: 'ClassroomProgramCourse' }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: { course_type: 'ClassroomProgramCourse' }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with status filter' do
      it 'generates CSV filtered by active status' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { status: 'active' }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: { status: 'active' }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with wiki_domain filter' do
      it 'generates CSV filtered by wiki domain' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { wiki_domain: 'en.wikipedia.org' }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: { wiki_domain: 'en.wikipedia.org' }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with date range filters' do
      it 'generates CSV filtered by date range' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: {
          start_date: 2.months.ago.to_date.to_s,
          end_date: 2.months.from_now.to_date.to_s
        }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: {
          start_date: 2.months.ago.to_date.to_s,
          end_date: 2.months.from_now.to_date.to_s
        }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with combined filters' do
      it 'generates CSV with multiple filters applied' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: {
          course_type: 'ClassroomProgramCourse',
          status: 'active',
          wiki_domain: 'en.wikipedia.org'
        }
        expect(response.body).to include('file is being generated')

        get '/system_csv', params: {
          course_type: 'ClassroomProgramCourse',
          status: 'active',
          wiki_domain: 'en.wikipedia.org'
        }
        follow_redirect!
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'filename uniqueness' do
      it 'generates different filenames for different filter combos' do
        expect(CsvCleanupWorker).to receive(:perform_at).twice
        get '/system_csv', params: { status: 'active' }
        get '/system_csv', params: { status: 'archived' }
        # Both should trigger generation (different filenames)
        expect(response.body).to include('file is being generated')
      end
    end
  end
end
