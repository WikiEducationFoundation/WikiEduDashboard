# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/errors/api_error_handling"

# Gets and processes data from Lift Wing
# https://wikitech.wikimedia.org/wiki/Machine_Learning/LiftWing
class LiftWingApi # rubocop:disable Metrics/ClassLength
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
    @wiki = wiki
    @update_service = update_service
    @errors = []
  end

  def get_revision_data(rev_ids)
    results = {}
    rev_ids.each do |rev_id|
      results.deep_merge!({ rev_id.to_s => get_single_revision_parsed_data(rev_id) })
    end

    log_error_batch(rev_ids)

    return results
  end

  private

  # Returns wp10, features, and deleted
  def get_single_revision_parsed_data(rev_id)
    body = { rev_id:, extended_output: true }.to_json
    response = lift_wing_server.post(quality_query_url, body)
    parsed_response = Oj.load(response.body)

    # If the responses contains an error, do not try to calculate wp10 or features.
    if parsed_response.key? 'error'
      return { 'wp10' => nil, 'features' => nil, 'deleted' => deleted?(parsed_response) }
    end

    score = parsed_response.dig(wiki_key, 'scores', rev_id.to_s, model_key)

    { 'wp10' => weighted_mean_score(score),
      'features' => score.dig('features'),
      'deleted' => false,
      'prediction' => score.dig('score', 'prediction') } # only for revision feedback
  rescue StandardError => e
    @errors << e
    return {}
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
    connection = Faraday.new(
      url: LIFT_WING_SERVER_URL,
      headers: {
        'Content-Type': 'application/json'
      }
    )
    # connection.headers['User-Agent'] = ENV['visualizer_url'] + ' ' + Rails.env
    connection
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

  # ORES articlequality ratings are often derived from the en.wiki system,
  # so this is the fallback scheme.
  ENWIKI_WEIGHTING = { 'FA'    => 100,
                       'GA'    => 80,
                       'B'     => 60,
                       'C'     => 40,
                       'Start' => 20,
                       'Stub'  => 0 }.freeze
  FRWIKI_WEIGHTING = { 'adq' => 100,
                       'ba' => 80,
                       'a' => 60,
                       'b' => 40,
                       'bd' => 20,
                       'e' => 0 }.freeze
  TRWIKI_WEIGHTING = { 'sm' => 100,
                       'km' => 80,
                       'b' => 60,
                       'c' => 40,
                       'baslagıç' => 20,
                       'taslak' => 0 }.freeze
  RUWIKI_WEIGHTING = { 'ИС' => 100,
                       'ДС' => 80,
                       'ХС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  PTWIKI_WEIGHTING = { '6' => 100,
                       '5' => 80,
                       '4' => 60,
                       '3' => 40,
                       '2' => 20,
                       '1' => 0 }.freeze
  UKWIKI_WEIGHTING = { 'ДС' => 100,
                       'ВС' => 80,
                       'I' => 60,
                       'II' => 40,
                       'III' => 20,
                       'IV' => 0 }.freeze
  # SV wiki has three high ratings, all of which are rare:
  # This is just a guess at appropriate weighting for the case where almost
  # all articles are the lowest tier.
  SVWIKI_WEIGHTING = { 'u' => 100,
                       'b' => 90,
                       'r' => 80,
                       's' => 0 }.freeze
  NLWIKI_WEIGHTING = { 'A' => 100,
                       'B' => 75,
                       'C' => 50,
                       'D' => 25,
                       'E' => 0 }.freeze
  WEIGHTING_BY_LANGUAGE = {
    'en' => ENWIKI_WEIGHTING,
    'simple' => ENWIKI_WEIGHTING,
    'fa' => ENWIKI_WEIGHTING,
    'eu' => ENWIKI_WEIGHTING,
    'fr' => FRWIKI_WEIGHTING,
    'tr' => TRWIKI_WEIGHTING,
    'ru' => RUWIKI_WEIGHTING,
    'uk' => UKWIKI_WEIGHTING,
    'gl' => ENWIKI_WEIGHTING,
    'sv' => SVWIKI_WEIGHTING,
    'nl' => NLWIKI_WEIGHTING,
    'pt' => PTWIKI_WEIGHTING
  }.freeze

  def weighting
    @weighting ||= WEIGHTING_BY_LANGUAGE[@wiki.language]
  end

  def weighted_mean_score(score)
    # This metric only makes sense to Wikipedia
    return unless @wiki.project == 'wikipedia'
    probability = score&.dig('score', 'probability')
    return unless probability
    mean = 0
    weighting.each do |rating, weight|
      mean += probability[rating] * weight
    end
    mean
  end
end
