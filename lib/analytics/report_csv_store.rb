# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/analytics/local_report_csv_store"
require_dependency "#{Rails.root}/lib/analytics/s3_report_csv_store"

#= Stores the CSV report exports built by ReportCsvWorker, and provides the urls
#= that users are sent to in order to download them.
# Deployments that set report_csv_bucket keep the reports in S3-compatible object
# storage, so that the reports can be generated on a different server than the one
# that serves them. Otherwise, they are kept on the local filesystem.
class ReportCsvStore
  def self.local
    LocalReportCsvStore.new
  end

  def self.s3
    S3ReportCsvStore.new
  end

  def self.exists?(filename)
    store.exists?(stored_name(filename))
  end

  def self.read(filename)
    store.read(stored_name(filename))
  end

  def self.write(filename, data)
    store.write(stored_name(filename), data)
  end

  def self.url_for(filename)
    store.url_for(stored_name(filename))
  end

  def self.delete(filename)
    store.delete(stored_name(filename))
  end

  def self.store
    @store ||= ENV['report_csv_bucket'].present? ? s3 : local
  end

  # Reports are served from a public location, and the names callers use are
  # built from slugs and the date. The stored name adds a suffix derived from
  # the app's secret, so a report can't be fetched by guessing its name.
  def self.stored_name(filename)
    extension = File.extname(filename)
    digest = OpenSSL::HMAC.hexdigest('SHA256', Rails.application.secret_key_base, filename)
    "#{filename.delete_suffix(extension)}-#{digest[0, 32]}#{extension}"
  end

  private_class_method :store, :stored_name
end
