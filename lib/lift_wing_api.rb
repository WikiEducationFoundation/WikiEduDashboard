# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"
require_dependency "#{Rails.root}/lib/weighted_score_calculator"

# Gets and processes data from Lift Wing
# https://wikitech.wikimedia.org/wiki/Machine_Learning/LiftWing
class LiftWingApi
  include ApiErrorHandling
  include WeightedScoreCalculator

<<<<<<< HEAD
  DELETED_REVISION_ERRORS = [
    'TextDeleted',
    'RevisionNotFound',
    'MW API does not have any info'
  ].freeze
=======
  DELETED_REVISION_ERRORS = %w[TextDeleted RevisionNotFound].freeze
>>>>>>> f3815a4f0 (Done)

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
    @wiki = wiki
    @update_service = update_service
    @errors = []
  end

  # Given an array of revision ids, it returns a hash with useful metrics for those
  # revision ids.
  # Format result example:
  # { 'rev_id0' => { 'wp10' => 0.2915228958136511656e2, 'features' => features_value,
  #                 'deleted' => false, 'prediction' => 'Stub' }
  #   ...
  #   'rev_idn' => { 'wp10' => 0.285936675221734978e2, 'features' => features_value,
  #                 'deleted' => false, 'prediction' => 'D' }
  # }
  def get_revision_data(rev_ids)
    # Restart errors array
    @errors = []
    results = {}
    rev_ids.each do |rev_id|
      results.deep_merge!({ rev_id.to_s => get_single_revision_parsed_data(rev_id) })
    end

    log_error_batch(rev_ids)

    return results
  end

  private

  # Returns a hash with wp10, features, deleted, and prediction, or empty hash if
  # there is an error.
  def get_single_revision_parsed_data(rev_id)
    tries ||= 5
    body = { rev_id:, extended_output: true }.to_json
    response = lift_wing_server.post(quality_query_url, body)
    parsed_response = Oj.load(response.body)
    # If the responses contain an error, do not try to calculate wp10 or features.
    if parsed_response.key? 'error'
      return { 'wp10' => nil, 'features' => nil, 'deleted' => deleted?(parsed_response),
      'prediction' => nil }
    end

    build_successful_response(rev_id, parsed_response)
  rescue StandardError => e
    tries -= 1
    retry unless tries.zero?
    @errors << e
    return { 'wp10' => nil, 'features' => nil, 'deleted' => false, 'prediction' => nil }
  end

  class InvalidProjectError < StandardError
  end

  # The top-level key representing the wiki in LiftWing data
  def wiki_key
    # This assumes the project is Wikipedia, which is true for all wikis with the articlequality
    # or the language is nil, which is the case for Wikidata.
    @wiki_key ||= "#{@wiki.language || @wiki.project}wiki"
  end

  def model_key
    @model_key ||= @wiki.project == 'wikidata' ? 'itemquality' : 'articlequality'
  end

  def quality_query_url
    "/service/lw/inference/v1/models/#{wiki_key}-#{model_key}:predict"
  end

  def lift_wing_server
    Faraday.new(
      url: LIFT_WING_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      }
    )
    # connection.headers['User-Agent'] = ENV['visualizer_url'] + ' ' + Rails.env
  end

  def build_successful_response(rev_id, response)
    score = response.dig(wiki_key, 'scores', rev_id.to_s, model_key)
    {
      # wp10 metric only makes sense to Wikipedia
      'wp10' => (if @wiki.project == 'wikipedia'
                   weighted_mean_score(score&.dig('score', 'probability'),
                                       @wiki.language)
                 end),
      'features' => score.dig('features'),
      'deleted' => false,
      'prediction' => score.dig('score', 'prediction') # only for revision feedback
    }
  end

  # TODO: monitor production for errors, understand them, put benign ones here
  TYPICAL_ERRORS = [].freeze

  def log_error_batch(rev_ids)
    return if @errors.empty?

    log_error(@errors.first, update_service: @update_service,
      sentry_extra: { rev_ids:, project_code: wiki_key,
                      project_model: model_key,
                      error_count: @errors.count })
  end

  def deleted?(response)
    LiftWingApi::DELETED_REVISION_ERRORS.any? do |revision_error|
      response.dig('error').include?(revision_error)
    end
  end
end
