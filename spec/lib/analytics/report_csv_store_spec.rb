# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/report_csv_store"

describe ReportCsvStore do
  # The selected store is memoized, so it has to be cleared between examples that
  # configure object storage differently. A local application.yml may or may not
  # configure it, so the setting is stubbed rather than assumed.
  before do
    described_class.instance_variable_set(:@store, nil)
    allow(ENV).to receive(:[]).and_call_original
  end

  after { described_class.instance_variable_set(:@store, nil) }

  describe 'store selection' do
    it 'uses the local store when no bucket is configured' do
      allow(ENV).to receive(:[]).with('report_csv_bucket').and_return(nil)
      expect(described_class.send(:store)).to be_a(LocalReportCsvStore)
    end

    it 'uses the S3 store when a bucket is configured' do
      allow(ENV).to receive(:[]).with('report_csv_bucket').and_return('reports')
      allow(Aws::S3::Client).to receive(:new)
      expect(described_class.send(:store)).to be_a(S3ReportCsvStore)
    end
  end

  describe 'delegation' do
    let(:store) { instance_double(LocalReportCsvStore) }
    # Stored names carry a secret-derived suffix so reports can't be guessed.
    let(:stored_name) { a_string_matching(/\Areport-\h{32}\.csv\z/) }

    before do
      allow(ENV).to receive(:[]).with('report_csv_bucket').and_return(nil)
      allow(LocalReportCsvStore).to receive(:new).and_return(store)
    end

    it 'delegates exists? to the store' do
      expect(store).to receive(:exists?).with(stored_name)
      described_class.exists?('report.csv')
    end

    it 'delegates read to the store' do
      expect(store).to receive(:read).with(stored_name)
      described_class.read('report.csv')
    end

    it 'delegates write to the store' do
      expect(store).to receive(:write).with(stored_name, 'data')
      described_class.write('report.csv', 'data')
    end

    it 'delegates url_for to the store' do
      expect(store).to receive(:url_for).with(stored_name)
      described_class.url_for('report.csv')
    end

    it 'delegates delete to the store' do
      expect(store).to receive(:delete).with(stored_name)
      described_class.delete('report.csv')
    end

    it 'gives the same report the same stored name' do
      names = []
      allow(store).to receive(:url_for) { |name| names << name }
      2.times { described_class.url_for('report.csv') }
      described_class.url_for('other.csv')
      expect(names[0]).to eq(names[1])
      expect(names[2]).not_to eq(names[0])
    end
  end
end
