# frozen_string_literal: true

require 'csv'
require 'faraday/follow_redirects'
require_dependency "#{Rails.root}/lib/errors/api_error_handling"

#= Keeps the list of valid grant IDs in sync with the Google Sheet set as
#= grant_ids_spreadsheet_url. The sheet has one ID per row under a
#= base_request_id header, and must be viewable by anyone with the link.
#= The IDs are stored in ValidGrantId so they can be checked without a request.
class GrantIdList
  include ApiErrorHandling

  ID_COLUMN = 'base_request_id'
  SHEET_ID_PATTERN = %r{docs\.google\.com/spreadsheets/d/([\w-]+)}
  TIMEOUT = 30
  REFRESH_INTERVAL = 5.minutes
  REFRESH_CACHE_KEY = 'grant_id_list_refresh_attempted'
  TYPICAL_ERRORS = [Faraday::TimeoutError, Faraday::ConnectionFailed].freeze

  class SpreadsheetError < StandardError; end

  def self.configured?
    ENV['grant_ids_spreadsheet_url'].present?
  end

  # Replaces the stored IDs with the spreadsheet's. Returns the number of IDs
  # stored, or nil if the sheet is not configured or could not be read, in
  # which case the previously stored IDs are kept.
  def self.refresh
    new.refresh
  end

  # Refreshes the list while a save waits for it, so this happens at most once
  # per REFRESH_INTERVAL, whether or not the sheet could be read.
  def self.refresh_unless_recent
    return if Rails.cache.exist?(REFRESH_CACHE_KEY)
    Rails.cache.write(REFRESH_CACHE_KEY, true, expires_in: REFRESH_INTERVAL)
    refresh
  end

  # Whether grant IDs can be checked. Fetches the list if none is stored yet.
  def self.available?
    ValidGrantId.exists? || refresh_unless_recent.present?
  end

  # An ID that is not stored may have been added to the sheet since the last
  # refresh, so the list is fetched again before the ID is turned down.
  def self.include?(grant_id)
    return true if ValidGrantId.exists?(grant_id:)
    refresh_unless_recent.present? && ValidGrantId.exists?(grant_id:)
  end

  def refresh
    return unless self.class.configured?
    grant_ids = fetch_grant_ids
    raise SpreadsheetError, 'The grant ID spreadsheet has no grant IDs' if grant_ids.empty?
    ValidGrantId.replace_all(grant_ids)
    grant_ids.count
  rescue StandardError => e
    log_error(e, sentry_extra: { url: export_url })
    nil
  end

  # Google Sheets serves a sheet as CSV from its export URL. A normal sheet
  # link (.../edit#gid=0) is turned into the export URL for the same tab;
  # any other URL is used as it is.
  def export_url
    url = ENV['grant_ids_spreadsheet_url'].to_s.strip
    sheet_id = url[SHEET_ID_PATTERN, 1]
    return url unless sheet_id
    gid = url[/[#&?]gid=(\d+)/, 1]
    export = "https://docs.google.com/spreadsheets/d/#{sheet_id}/export?format=csv"
    gid ? "#{export}&gid=#{gid}" : export
  end

  private

  def fetch_grant_ids
    response = connection.get(export_url)
    unless response.success?
      raise SpreadsheetError, "Grant ID spreadsheet returned #{response.status}"
    end
    parse(response.body)
  end

  def parse(body)
    table = CSV.parse(body, headers: true)
    unless table.headers.include?(ID_COLUMN)
      # Google serves a sign-in page instead when the sheet is not shared publicly.
      raise SpreadsheetError, "The grant ID spreadsheet has no #{ID_COLUMN} column"
    end
    table.filter_map { |row| row[ID_COLUMN]&.strip.presence }.uniq
  end

  def connection
    Faraday.new do |conn|
      conn.response :follow_redirects
      conn.options.timeout = TIMEOUT
      conn.headers['User-Agent'] = "#{ENV['dashboard_url']} #{Rails.env}"
    end
  end
end
