# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/csv_cleanup_worker"

describe CsvCleanupWorker do
  it 'raises an S3 error, so that Sidekiq retries the cleanup' do
    error = Aws::S3::Errors::ServiceError.new(nil, 'Bad Request')
    allow(ReportCsvStore).to receive(:delete).and_raise(error)
    expect { described_class.new.perform('report.csv') }.to raise_error(error)
  end

  it 'skips a file the local store doesn\'t have' do
    expect { described_class.new.perform('never-written.csv') }.not_to raise_error
  end
end
