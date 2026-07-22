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
      it 'enqueues a background job and returns 202 with generating status' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv'
        expect(response).to have_http_status(:accepted)
        json = response.parsed_body
        expect(json['status']).to eq('generating')
      end

      it 'returns ready status with URL on second request after generation' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv'
        expect(response).to have_http_status(:accepted)

        get '/system_csv'
        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json['status']).to eq('ready')
        expect(json['url']).to end_with('.csv')

        get json['url']
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
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: { campaign_slug: 'test_campaign' }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with course_type filter' do
      it 'generates CSV filtered by course type' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { course_type: 'ClassroomProgramCourse' }
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: { course_type: 'ClassroomProgramCourse' }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with status filter' do
      it 'generates CSV filtered by active status' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { status: 'active' }
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: { status: 'active' }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'with wiki_domain filter' do
      it 'generates CSV filtered by wiki domain' do
        expect(CsvCleanupWorker).to receive(:perform_at)
        get '/system_csv', params: { wiki_domain: 'en.wikipedia.org' }
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: { wiki_domain: 'en.wikipedia.org' }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
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
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: {
          start_date: 2.months.ago.to_date.to_s,
          end_date: 2.months.from_now.to_date.to_s
        }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
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
        expect(response).to have_http_status(:accepted)

        get '/system_csv', params: {
          course_type: 'ClassroomProgramCourse',
          status: 'active',
          wiki_domain: 'en.wikipedia.org'
        }
        json = response.parsed_body
        expect(json['status']).to eq('ready')

        get json['url']
        csv = response.body.force_encoding('utf-8')
        expect(csv).to include('Test Course')
      end
    end

    describe 'filename uniqueness' do
      it 'generates different filenames for different filter combos' do
        expect(CsvCleanupWorker).to receive(:perform_at).twice
        get '/system_csv', params: { status: 'active' }
        expect(response).to have_http_status(:accepted)
        get '/system_csv', params: { status: 'archived' }
        expect(response).to have_http_status(:accepted)
      end
    end

    describe 'filter validation' do
      it 'returns 422 for invalid course_type' do
        get '/system_csv', params: { course_type: 'Bogus' }
        expect(response).to have_http_status(422)
        json = response.parsed_body
        expect(json['error']).to include('Invalid course_type')
      end

      it 'returns 422 for invalid status' do
        get '/system_csv', params: { status: 'invalid' }
        expect(response).to have_http_status(422)
        json = response.parsed_body
        expect(json['error']).to include('Invalid status')
      end

      it 'returns 422 for malformed date' do
        get '/system_csv', params: { start_date: 'not-a-date' }
        expect(response).to have_http_status(422)
        json = response.parsed_body
        expect(json['error']).to include('Invalid start_date')
      end

      it 'returns 422 for nonexistent campaign' do
        get '/system_csv', params: { campaign_slug: 'nonexistent' }
        expect(response).to have_http_status(422)
        json = response.parsed_body
        expect(json['error']).to include('Campaign not found')
      end

      it 'returns 422 with multiple errors' do
        get '/system_csv', params: {
          course_type: 'Bogus',
          status: 'invalid'
        }
        expect(response).to have_http_status(422)
        json = response.parsed_body
        expect(json['error']).to include('Invalid course_type')
        expect(json['error']).to include('Invalid status')
      end
    end
  end
end
