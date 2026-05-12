# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# Gets data from reference-counter Toolforge tool
# https://toolsadmin.wikimedia.org/tools/id/reference-counter
#
# Uses the batch endpoint (POST /api/v1/references/{project}/{language}) so a
# group of revisions costs one HTTP round-trip instead of N. Suppressed/deleted
# revisions surface as per-rev `{ "num_ref": null, "error": "no content" }`
# entries inside an otherwise-200 response.
class ReferenceCounterApi
  include ApiErrorHandling

  TOOLFORGE_SERVER_URL = 'https://reference-counter.toolforge.org'
  RETRY_COUNT = 5
  MAX_NON_200_RESPONSE_LOGS = 5

  # The reference-counter Toolforge API only supports language-edition wikis
  # (en.wikipedia, fr.wiktionary, etc.). Wikidata is excluded because it has
  # its own data model and reference-counting approach. The wikimedia
  # pseudo-project (commons, meta, incubator, species, foundationwiki) is
  # excluded because none of its members are language-edition wikis with
  # article-style <ref> markup; the API responds with 400 "Language X is not
  # a valid language" for any of them.
  UNSUPPORTED_PROJECTS = %w[wikidata wikimedia].freeze

  def self.valid_wiki?(wiki)
    !UNSUPPORTED_PROJECTS.include?(wiki.project)
  end

  def initialize(wiki, update_service = nil)
    raise InvalidProjectError unless ReferenceCounterApi.valid_wiki?(wiki)
    @project_code = wiki.project
    @language_code = wiki.language
    @update_service = update_service
    @errors = []
    @non_200_errors = {}
  end

  # Given an array of revision ids, returns a hash:
  #   { 'rev_id0' => { 'num_ref' => 10 }, ... 'rev_idn' => { 'num_ref' => 0 } }
  # Suppressed/deleted revisions return { 'num_ref' => nil } (with no 'error'
  # key, matching the prior 403 path) and tick record_reference_counter_403 on
  # the update service so we surface a per-update count.
  def get_number_of_references_from_revision_ids(rev_ids)
    @errors = []
    return {} if rev_ids.empty?

    results = fetch_batch(rev_ids)

    log_error_batch(rev_ids)
    report_reference_counter_error_to_sentry
    results
  end

  private

  def fetch_batch(rev_ids)
    tries ||= RETRY_COUNT
    response = toolforge_server.post(batch_query_url) do |req|
      req.body = { 'rev_ids' => rev_ids }.to_json
    end
    parsed_response = Oj.load(response.body)
    handle_batch_response(rev_ids, response.status, parsed_response)
  rescue StandardError => e
    tries -= 1
    retry unless tries.zero?
    @errors << e
    rev_ids.to_h { |id| [id.to_s, { 'num_ref' => nil, 'error' => e }] }
  end

  def handle_batch_response(rev_ids, status, parsed_response)
    return normalize_batch_results(rev_ids, parsed_response) if status == 200

    batch_non_200_response_log(status, { rev_ids:, content: parsed_response })
    rev_ids.to_h { |id| [id.to_s, { 'num_ref' => nil, 'error' => parsed_response }] }
  end

  def normalize_batch_results(rev_ids, parsed_response)
    rev_ids.each_with_object({}) do |rev_id, results|
      entry = parsed_response[rev_id.to_s]
      results[rev_id.to_s] = transform_entry(entry)
    end
  end

  # Per-rev entry shape from the batch endpoint (input):
  #   { 'num_ref' => N }                                  # normal
  #   { 'num_ref' => nil, 'error' => 'no content' }       # suppressed/deleted
  #   nil                                                 # missing from response
  # Transformed output:
  #   { 'num_ref' => N }                                  # normal
  #   { 'num_ref' => nil, 'deleted' => true }             # suppressed/deleted
  #   { 'num_ref' => nil }                                # missing from response
  def transform_entry(entry)
    return { 'num_ref' => nil } if entry.nil?
    return handle_forbidden if suppressed_content?(entry)
    { 'num_ref' => entry['num_ref'] }
  end

  def suppressed_content?(entry)
    entry['num_ref'].nil? && entry['error'] == 'no content'
  end

  # Suppressed-content revs are expected for revisions whose content has been
  # hidden (texthidden / revdeleted). Count them on the update service so we
  # surface a total per course update, and skip Sentry reporting.
  def handle_forbidden
    @update_service&.record_reference_counter_403
    { 'num_ref' => nil, 'deleted' => true }
  end

  def error_key(status)
    status.to_s
  end

  def report_reference_counter_error_to_sentry
    return if @non_200_errors.empty?

    @non_200_errors.each_value do |data|

      error = StandardError.new("Non-200 response hitting references
                                counter API: (#{data[:status_code]})")

      # Use the shared module method
      log_error(error,
        update_service: @update_service,
        sentry_extra: {
          project_code: @project_code,
          language_code: @language_code,
          error_count: data[:error_count],
          errors: data[:errors],
          status: data[:status_code]
        }
      )
    end

    @non_200_errors = {}
  end


  def batch_non_200_response_log(status, error_response)
    # Initialize if new status
    @non_200_errors[error_key(status)] ||= { error_count: 0, status_code: status, errors: [] }

    # Increment count every time
    @non_200_errors[error_key(status)][:error_count] += 1

    # Only collect the error details if under the limit
    if @non_200_errors[error_key(status)][:error_count] <= MAX_NON_200_RESPONSE_LOGS
      @non_200_errors[error_key(status)][:errors] << error_response
    end
  end


  class InvalidProjectError < StandardError
  end

  def batch_query_url
    "/api/v1/references/#{@project_code}/#{@language_code}"
  end

  # A batch lookup has no reason to take longer than this. Without timeouts,
  # a silent server leaves the worker blocked in IO#wait_readable indefinitely
  # — Faraday::TimeoutError is already in TYPICAL_ERRORS and the 5-retry
  # rescue below will handle transient failures gracefully.
  OPEN_TIMEOUT = 30
  REQUEST_TIMEOUT = 60

  def toolforge_server
    Faraday.new(
      url: TOOLFORGE_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      },
      request: { open_timeout: OPEN_TIMEOUT, timeout: REQUEST_TIMEOUT }
    )
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Faraday::ConnectionFailed,
                    StandardError].freeze

  def log_error_batch(rev_ids)
    return if @errors.empty?

    log_error(@errors.first, update_service: @update_service,
    sentry_extra: { rev_ids:, project_code: @project_code,
    language_code: @language_code, error_count: @errors.count })
  end
end
