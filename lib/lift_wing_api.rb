# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# Gets data from Lift Wing
# https://wikitech.wikimedia.org/wiki/Machine_Learning/LiftWing
class LiftWingApi
  include ApiErrorHandling

  DELETED_REVISION_ERRORS = %w[TextDeleted RevisionNotFound].freeze

  LIFT_WING_SERVER_URL = 'https://api.wikimedia.org'

  # All the wikis with an articlequality model as of 2023-06-28
  # https://wikitech.wikimedia.org/wiki/Machine_Learning/LiftWingq
  AVAILABLE_WIKIPEDIAS = %w[en eu fa fr gl nl pt ru sv tr uk].freeze

  def self.valid_wiki?(wiki)
    return true if wiki.project == 'wikidata'
    wiki.project == 'wikipedia' && AVAILABLE_WIKIPEDIAS.include?(wiki.language)
  end

  def initialize(wiki, update_service = nil)
    raise InvalidProjectError unless LiftWingApi.valid_wiki?(wiki)
    @project_code = wiki.project == 'wikidata' ? 'wikidata' + 'wiki' : wiki.language + 'wiki'
    @project_quality_model = wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'
    @update_service = update_service
    @errors = []
  end

  def get_revision_data(rev_ids)
    results = {}
    rev_ids.each do |rev_id|
      results.deep_merge! get_single_revision_data(rev_id)
    end

    log_error_batch(rev_ids)

    return results
  end

  def get_single_revision_data(rev_id)
    body = { rev_id:, extended_output: true }.to_json
    response = lift_wing_server.post(quality_query_url, body)
    parsed_response = Oj.load(response.body)

    return equivalent_ores_error_response(rev_id, parsed_response) if parsed_response.key? 'error'

    parsed_response
  rescue StandardError => e
    @errors << e
    return {}
  end

  class InvalidProjectError < StandardError
  end

  private

  def quality_query_url
    "/service/lw/inference/v1/models/#{@project_code}-#{@project_quality_model}:predict"
  end

  def lift_wing_server
    connection = Faraday.new(
      url: LIFT_WING_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      }
    )
    # connection.headers['User-Agent'] = ENV['visualizer_url'] + ' ' + Rails.env
    connection
  end

  # To make migration from ORES to LiftWing easier, we want responses to be in the same format,
  # including error responses.
  # For a deleted revision, ORES returns something like this:
  # {"enwiki"=>{"scores"=>{"708326238"=>{"articlequality"=>{"error"=>
  #   {"message"=>"TextDeleted: Text deleted (datasource.revision.text)",
  #    "type"=>"TextDeleted"}}}}}}
  # Lift Wing just returns something like:
  # {"error"=>
  #  "Missing resource for rev-id 708326238: TextDeleted: Text deleted (datasource.revision.text)"}
  ERROR_TYPE_MATCHER = Regexp.union DELETED_REVISION_ERRORS

  def equivalent_ores_error_response(rev_id, error_response)
    message = error_response['error']
    type = message[ERROR_TYPE_MATCHER]

    { @project_code =>
      { 'scores' => { rev_id.to_s => { @project_quality_model => {
        'error' => { 'message' => error_response['error'], 'type' => type } } } } } }
  end

  # TODO: monitor production for errors, understand them, put benign ones here
  TYPICAL_ERRORS = [].freeze

  def log_error_batch(rev_ids)
    return if @errors.empty?

    log_error(@errors.first, update_service: @update_service,
      sentry_extra: { rev_ids:, project_code: @project_code,
                      project_model: @project_quality_model,
                      error_count: @errors.count })
  end
end
