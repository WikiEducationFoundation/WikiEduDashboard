# frozen_string_literal: true

require 'rails_helper'

describe ReportsController, '#system_daily_stats_csv', :report_csv_files, type: :request do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }

  let!(:stat) do
    create(:system_stat, snapshot_date: 5.days.ago.to_date,
                         total_edits: 800)
  end

  context 'when not signed in' do
    it 'returns 401 unauthorized' do
      get '/system_daily_stats_csv'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in as a non-admin' do
    before { login_as user }

    it 'returns 401 unauthorized' do
      get '/system_daily_stats_csv'
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context 'when signed in as an admin' do
    before { login_as admin }

    it 'enqueues job and returns 202 status' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/system_daily_stats_csv', params: {
        start_date: 10.days.ago.to_date.to_s,
        end_date: Time.zone.today.to_s
      }
      expect(response).to have_http_status(:accepted)
      json = response.parsed_body
      expect(json['status']).to eq('generating')
    end

    it 'returns ready status on subsequent request' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/system_daily_stats_csv', params: {
        start_date: 10.days.ago.to_date.to_s,
        end_date: Time.zone.today.to_s
      }
      expect(response).to have_http_status(:accepted)

      get '/system_daily_stats_csv', params: {
        start_date: 10.days.ago.to_date.to_s,
        end_date: Time.zone.today.to_s
      }
      expect(response).to have_http_status(:ok)
      json = response.parsed_body
      expect(json['status']).to eq('ready')

      get json['url']
      csv = response.body.force_encoding('utf-8')
      expect(csv).to include('snapshot_date')
      expect(csv).to include('800')
    end

    it 'works without any date params (uses defaults)' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/system_daily_stats_csv'
      expect(response).to have_http_status(:accepted)
      json = response.parsed_body
      expect(json['status']).to eq('generating')
    end

    it 'returns 422 for invalid start_date' do
      get '/system_daily_stats_csv', params: {
        start_date: 'not-a-date',
        end_date: Time.zone.today.to_s
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to include('Invalid start_date')
    end

    it 'returns 422 when start_date is after end_date' do
      get '/system_daily_stats_csv', params: {
        start_date: Time.zone.today.to_s,
        end_date: 10.days.ago.to_date.to_s
      }
      expect(response).to have_http_status(:unprocessable_content)
      json = response.parsed_body
      expect(json['error']).to include('start_date must be before end_date')
    end

    it 'normalizes slash-delimited dates in the filename' do
      expect(CsvCleanupWorker).to receive(:perform_at)
      get '/system_daily_stats_csv', params: { start_date: '2020/01/02' }
      expect(response).to have_http_status(:accepted)

      get '/system_daily_stats_csv', params: { start_date: '2020/01/02' }
      expect(response).to have_http_status(:ok)
      url = response.parsed_body['url']
      # The URL should not contain raw slashes from the date param
      filename = url.split('/').last
      expect(filename).not_to include('2020/01/02')
      expect(filename).to include('from-2020-01-02')
    end
  end
end
