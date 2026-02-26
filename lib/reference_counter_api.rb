# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# Gets data from reference-counter Toolforge tool
# https://toolsadmin.wikimedia.org/tools/id/reference-counter
class ReferenceCounterApi
  include ApiErrorHandling

  TOOLFORGE_SERVER_URL = 'https://reference-counter.toolforge.org'
  RETRY_COUNT = 5
  MAX_NON_200_RESPONSE_LOGS = 5

  # This class is not designed for use with wikidata, as that wiki works pretty
  # different from other wikis and it has its own method of calculating references.
  # The reference-counter Toolforge API doesn't work for wikidata either for the
  # same reason.
  def self.valid_wiki?(wiki)
    return wiki.project != 'wikidata'
  end

  def initialize(wiki, update_service = nil)
    raise InvalidProjectError unless ReferenceCounterApi.valid_wiki?(wiki)
    @project_code = wiki.project
    @language_code = wiki.language
    @update_service = update_service
    @errors = []
    @sentry_logs = {}
  end

  # This is the main entry point.
  # Given an array of revision ids, it returns a hash with the number of references
  # for those revision ids.
  # Format result example:
  # { 'rev_id0' => { 'num_ref' => 10 }
  #   ...
  #   'rev_idn' => { "num_ref" => 0 }
  # }
  def get_number_of_references_from_revision_ids(rev_ids)
    # Restart errors array
    @errors = []
    results = {}
    rev_ids.each do |rev_id|
      results.deep_merge!({ rev_id.to_s => get_number_of_references_from_revision_id(rev_id) })
    end

    log_error_batch(rev_ids)
    report_reference_counter_error_to_sentry
    return results
  end

  private

  # Given a revision ID, it retrieves a hash containing the reference count from the
  # reference-counter Toolforge API.
  # If the API response is not 200 or an error occurs, it returns nil.
  # Any encountered errors are logged in Sentry at the batch level.
  def get_number_of_references_from_revision_id(rev_id)
    tries ||= RETRY_COUNT
    response = toolforge_server.get(references_query_url(rev_id))
    parsed_response = Oj.load(response.body)
   
    return { 'num_ref' => parsed_response['num_ref'] } if response.status == 200
   
    if response.status != 200
      error_response = { rev_id: rev_id, content: parsed_response}
      batch_non_200_response_log(response.status, error_response)
    end
    # Leave the error empty if it is not a transient error.
    return { 'num_ref' => nil } if non_transient_error? response.status
    # Log the error and return empty hash
    return { 'num_ref' => nil, 'error' => parsed_response }
  rescue StandardError => e
    tries -= 1
    retry unless tries.zero?
    @errors << e
    return { 'num_ref' => nil, 'error' => e }
  end

  def error_key(status)
    status.to_s
  end
  
  def report_reference_counter_error_to_sentry
    return if @sentry_logs.empty?

    @sentry_logs.each_value do |data|
      status = data[:status_code]
      
      Sentry.capture_message(
        "Non-200 response hitting references counter API: #{status}",
        level: 'warning',
        # This ensures all errors with this status code group together
        fingerprint: ['references-counter-api-error', status.to_s],
        extra: {
          project_code: @project_code,
          language_code: @language_code,
          error_count: data[:error_count],
          errors: data[:errors]
        }
      )
    end
    
    @sentry_logs = {}
  end


  def batch_non_200_response_log(status, error_response)
    # Initialize if new status
    @sentry_logs[error_key(status)] ||= { error_count: 0, status_code: status, errors: [] }
    
    # Increment count every time
    @sentry_logs[error_key(status)][:error_count] += 1
    
    # Only collect the error details if under the limit
    if @sentry_logs[error_key(status)][:error_count] <= MAX_NON_200_RESPONSE_LOGS
      @sentry_logs[error_key(status)][:errors] << error_response
    end
  end


  class InvalidProjectError < StandardError
  end

  def references_query_url(rev_id)
    "/api/v1/references/#{@project_code}/#{@language_code}/#{rev_id}"
  end

  def toolforge_server
    Faraday.new(
      url: TOOLFORGE_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      }
    )
  end

  BAD_REQUEST = 400
  FORBIDDEN = 403
  NOT_FOUND = 404
  # A bad request response indicates that the language and/or project is not supported.
  # A forbidden response likely means we lack permission to access the revision,
  # possibly because it was deleted or hidden.
  def non_transient_error?(status)
    [BAD_REQUEST, FORBIDDEN, NOT_FOUND].include? status
  end

  TYPICAL_ERRORS = [Faraday::TimeoutError,
                    Faraday::ConnectionFailed].freeze

  def log_error_batch(rev_ids)
    return if @errors.empty?

    log_error(@errors.first, update_service: @update_service,
    sentry_extra: { rev_ids:, project_code: @project_code,
    language_code: @language_code, error_count: @errors.count })
  end
end
