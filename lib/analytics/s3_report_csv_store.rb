# frozen_string_literal: true

#= Keeps report CSVs in S3-compatible object storage, so that they can be written by
#= one server and downloaded from another. The bucket must allow anonymous reads,
#= because users are redirected to the object url to download their report.
class S3ReportCsvStore
  REGION = 'default'

  def initialize
    @bucket = ENV['report_csv_bucket']
    @public_url = ENV['report_csv_public_url']
    @client = Aws::S3::Client.new(
      endpoint: ENV['report_csv_s3_endpoint'],
      access_key_id: ENV['report_csv_access_key'],
      secret_access_key: ENV['report_csv_secret_key'],
      region: REGION,
      # The gateway serves every bucket from a single hostname, so bucket names must
      # go in the request path instead of the domain.
      force_path_style: true
    )
  end

  def exists?(filename)
    @client.head_object(bucket: @bucket, key: filename)
    true
  rescue Aws::S3::Errors::NotFound
    false
  rescue Aws::S3::Errors::ServiceError => e
    Sentry.capture_exception(e, extra: { filename: })
    false
  end

  def write(filename, data)
    @client.put_object(bucket: @bucket, key: filename, body: data, content_type: 'text/csv')
  end

  def url_for(filename)
    "#{@public_url}/#{filename}"
  end

  def delete(filename)
    @client.delete_object(bucket: @bucket, key: filename)
  end
end
