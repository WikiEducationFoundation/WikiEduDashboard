# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/grant_id_list"

describe GrantIdList do
  let(:sheet_url) { 'https://docs.google.com/spreadsheets/d/abc-123_XYZ/edit#gid=456' }
  let(:export_url) do
    'https://docs.google.com/spreadsheets/d/abc-123_XYZ/export?format=csv&gid=456'
  end
  let(:sheet_csv) { "base_request_id\n1546-24563\n 2001-00042 \n\n1546-24563\n" }

  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('grant_ids_spreadsheet_url').and_return(sheet_url)
  end

  describe '#export_url' do
    it 'turns a sheet link into the CSV export URL for the same tab' do
      expect(described_class.new.export_url).to eq(export_url)
    end

    it 'leaves out the tab when the link does not name one' do
      allow(ENV).to receive(:[]).with('grant_ids_spreadsheet_url')
                                .and_return('https://docs.google.com/spreadsheets/d/abc/edit')
      expect(described_class.new.export_url)
        .to eq('https://docs.google.com/spreadsheets/d/abc/export?format=csv')
    end

    it 'uses any other URL as it is' do
      allow(ENV).to receive(:[]).with('grant_ids_spreadsheet_url')
                                .and_return('https://example.org/grants.csv')
      expect(described_class.new.export_url).to eq('https://example.org/grants.csv')
    end
  end

  describe '.refresh' do
    it 'stores the stripped, de-duplicated IDs from the base_request_id column' do
      stub_request(:get, export_url).to_return(status: 200, body: sheet_csv)
      expect(described_class.refresh).to eq(2)
      expect(ValidGrantId.pluck(:grant_id)).to contain_exactly('1546-24563', '2001-00042')
    end

    it 'follows the redirect Google sends for exports' do
      stub_request(:get, export_url)
        .to_return(status: 307, headers: { 'Location' => 'https://sheets.example.org/csv' })
      stub_request(:get, 'https://sheets.example.org/csv').to_return(status: 200, body: sheet_csv)
      expect(described_class.refresh).to eq(2)
    end

    it 'replaces IDs that are no longer on the sheet' do
      ValidGrantId.replace_all(%w[0000-0001])
      stub_request(:get, export_url).to_return(status: 200, body: sheet_csv)
      described_class.refresh
      expect(ValidGrantId.exists?(grant_id: '0000-0001')).to be(false)
    end

    context 'when the sheet cannot be used' do
      before { ValidGrantId.replace_all(%w[0000-0001]) }

      it 'keeps the stored IDs if the request fails' do
        stub_request(:get, export_url).to_return(status: 500)
        expect(Sentry).to receive(:capture_exception)
        expect(described_class.refresh).to be_nil
        expect(ValidGrantId.pluck(:grant_id)).to eq(%w[0000-0001])
      end

      it 'keeps the stored IDs if the sheet has no base_request_id column' do
        stub_request(:get, export_url).to_return(status: 200, body: '<html>Sign in</html>')
        expect(described_class.refresh).to be_nil
        expect(ValidGrantId.pluck(:grant_id)).to eq(%w[0000-0001])
      end

      it 'keeps the stored IDs if the sheet has no grant IDs' do
        stub_request(:get, export_url).to_return(status: 200, body: "base_request_id\n")
        expect(described_class.refresh).to be_nil
        expect(ValidGrantId.pluck(:grant_id)).to eq(%w[0000-0001])
      end
    end

    it 'does nothing when no spreadsheet is configured' do
      allow(ENV).to receive(:[]).with('grant_ids_spreadsheet_url').and_return(nil)
      expect(described_class.refresh).to be_nil
      expect(a_request(:get, /docs\.google\.com/)).not_to have_been_made
    end
  end

  describe '.available?' do
    it 'fetches the sheet when no IDs are stored yet' do
      stub_request(:get, export_url).to_return(status: 200, body: sheet_csv)
      expect(described_class.available?).to be(true)
      expect(described_class.include?('1546-24563')).to be(true)
    end

    it 'does not fetch the sheet when IDs are already stored' do
      ValidGrantId.replace_all(%w[0000-0001])
      expect(described_class.available?).to be(true)
      expect(a_request(:get, export_url)).not_to have_been_made
    end

    it 'is false when the sheet cannot be read and no IDs are stored' do
      stub_request(:get, export_url).to_return(status: 500)
      expect(described_class.available?).to be(false)
    end
  end

  describe '.include?' do
    # The test environment has no cache, so the limit on refreshes needs one.
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }

    before do
      allow(Rails).to receive(:cache).and_return(cache)
      ValidGrantId.replace_all(%w[1546-24563])
      stub_request(:get, export_url).to_return(status: 200, body: sheet_csv)
    end

    it 'only matches an ID exactly as listed' do
      expect(described_class.include?('1546-24563')).to be(true)
      expect(described_class.include?('G-1546-24563')).to be(false)
    end

    it 'does not fetch the sheet for an ID that is already stored' do
      described_class.include?('1546-24563')
      expect(a_request(:get, export_url)).not_to have_been_made
    end

    it 'finds an ID added to the sheet since the last refresh' do
      expect(described_class.include?('2001-00042')).to be(true)
    end

    it 'fetches the sheet only once for IDs that are not on it' do
      described_class.include?('9999-99999')
      described_class.include?('8888-88888')
      expect(a_request(:get, export_url)).to have_been_made.once
    end

    it 'fetches the sheet again once the refresh interval has passed' do
      described_class.include?('9999-99999')
      travel_to(Time.zone.now + described_class::REFRESH_INTERVAL + 1.second) do
        described_class.include?('8888-88888')
      end
      expect(a_request(:get, export_url)).to have_been_made.twice
    end

    it 'does not keep fetching a sheet that cannot be read' do
      stub_request(:get, export_url).to_return(status: 500)
      2.times { expect(described_class.include?('9999-99999')).to be(false) }
      expect(a_request(:get, export_url)).to have_been_made.once
    end
  end
end
