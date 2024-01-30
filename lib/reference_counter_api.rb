# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# Gets data from reference-counter Toolforge tool
# https://toolsadmin.wikimedia.org/tools/id/reference-counter
class ReferenceCounterApi
  include ApiErrorHandling

  TOOLFORGE_SERVER_URL = 'https://reference-counter.toolforge.org'

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

    return results
  end

  private

  # Given a revision ID, it retrieves a hash containing the reference count from the
  # reference-counter Toolforge API.
  # If the API response is not 200 or an error occurs, it returns nil.
  # Any encountered errors are logged in Sentry at the batch level.
  def get_number_of_references_from_revision_id(rev_id)
    tries ||= 5
    response = toolforge_server.get(references_query_url(rev_id))
    parsed_response = Oj.load(response.body)
    if response.status == 200
      return { 'num_ref' => parsed_response['num_ref'] }
    else
      # Log the error and return empty hash
      Sentry.capture_message 'Non-200 response hitting references counter API', level: 'warning',
      extra: { project_code: @project_code, language_code: @language_code, rev_id:,
                             status_code: response.status, content: parsed_response }
      return { 'num_ref' => nil }
    end
  rescue StandardError => e
    tries -= 1
    retry unless tries.zero?
    @errors << e
    return { 'num_ref' => nil }
  end

  class InvalidProjectError < StandardError
  end

  def references_query_url(rev_id)
    "/api/v1/references/#{@project_code}/#{@language_code}/#{rev_id}"
  end

  def toolforge_server
    connection = Faraday.new(
      url: TOOLFORGE_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      }
    )
    connection
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
