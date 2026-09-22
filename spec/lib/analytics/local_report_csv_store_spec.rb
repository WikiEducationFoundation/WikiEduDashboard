# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/local_report_csv_store"

describe LocalReportCsvStore do
  let(:store) { described_class.new }
  let(:filename) { 'course-overview-2026-08-20.csv' }
  let(:path) { "public#{LocalReportCsvStore::CSV_PATH}/#{filename}" }

  after do
    File.delete(path) if File.exist?(path)
  end

  describe '#write' do
    it 'creates the file under the public directory' do
      store.write(filename, "a,b\n1,2\n")
      expect(File.read(path)).to eq("a,b\n1,2\n")
    end
  end

  describe '#exists?' do
    it 'returns false when the report has not been generated' do
      expect(store.exists?(filename)).to eq(false)
    end

    it 'returns true once the report has been written' do
      store.write(filename, 'data')
      expect(store.exists?(filename)).to eq(true)
    end
  end

  describe '#url_for' do
    it 'returns the path the file is served from' do
      expect(store.url_for(filename)).to eq("/system/analytics/#{filename}")
    end
  end

  describe '#delete' do
    it 'removes the file' do
      store.write(filename, 'data')
      store.delete(filename)
      expect(File.exist?(path)).to eq(false)
    end
  end
end
