# frozen_string_literal: true

# Request specs that exercise the real CSV export pipeline write report files into
# public/system/analytics, a directory that every parallel_rspec process shares. A
# spec must therefore only ever remove the files it wrote itself: deleting the whole
# directory pulls another process's report out from under it between the write and
# the request that expects to find it, which showed up in CI as intermittent
# "expected ready, got generating" failures (#7040).
#
# Tag an example group with `:report_csv_files` to record each file written through
# ReportCsvStore during an example and delete exactly those files afterwards.
RSpec.configure do |config|
  config.before(:each, :report_csv_files) do
    @report_csv_files_written = []
    allow(ReportCsvStore).to receive(:write).and_wrap_original do |original, filename, data|
      @report_csv_files_written << filename
      original.call(filename, data)
    end
  end

  config.after(:each, :report_csv_files) do
    @report_csv_files_written.each do |filename|
      ReportCsvStore.delete(filename) if ReportCsvStore.exists?(filename)
    end
  end
end
