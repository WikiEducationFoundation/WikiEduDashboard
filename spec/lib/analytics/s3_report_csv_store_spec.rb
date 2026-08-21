# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/s3_report_csv_store"

describe S3ReportCsvStore do
  let(:client) { instance_double(Aws::S3::Client) }
  let(:store) { described_class.new }
  let(:filename) { 'course-overview-2026-08-20.csv' }

  before do
    ENV['report_csv_bucket'] = 'reports'
    ENV['report_csv_public_url'] = 'https://object.example.org/project:reports'
    allow(Aws::S3::Client).to receive(:new).and_return(client)
  end

  after do
    ENV.delete('report_csv_bucket')
    ENV.delete('report_csv_public_url')
  end

  describe '#write' do
    it 'uploads the report to the bucket' do
      expect(client).to receive(:put_object)
        .with(bucket: 'reports', key: filename, body: 'data', content_type: 'text/csv')
      store.write(filename, 'data')
    end
  end

  describe '#exists?' do
    it 'returns true when the object is there' do
      allow(client).to receive(:head_object).with(bucket: 'reports', key: filename)
      expect(store.exists?(filename)).to eq(true)
    end

    it 'returns false when the object is not there' do
      allow(client).to receive(:head_object)
        .and_raise(Aws::S3::Errors::NotFound.new(nil, 'Not Found'))
      expect(store.exists?(filename)).to eq(false)
    end

    it 'returns false and logs to sentry if other errors surface' do
      allow(client).to receive(:head_object)
        .and_raise(Aws::S3::Errors::AccessDenied.new(nil, 'Access Denied'))
      expect(Sentry).to receive(:capture_exception)
        .with(instance_of(Aws::S3::Errors::AccessDenied), extra: { filename: })
      expect(store.exists?(filename)).to eq(false)
    end
  end

  describe '#url_for' do
    it 'returns the public url of the object' do
      expect(store.url_for(filename))
        .to eq("https://object.example.org/project:reports/#{filename}")
    end
  end

  describe '#delete' do
    it 'deletes the object' do
      expect(client).to receive(:delete_object).with(bucket: 'reports', key: filename)
      store.delete(filename)
    end
  end
end
