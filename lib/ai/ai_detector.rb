# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
require_dependency "#{Rails.root}/lib/ai/pangram_response_parser"
require_dependency "#{Rails.root}/lib/ai/originality_response_parser"

# Registry of the AI text detectors the Dashboard can call, keyed by the
# RevisionAiScore#check_type their results are stored under. Each entry pairs
# an API client (anything responding to #inference(text)) with the parser that
# turns the raw response into the shared DetectorSummary shape, so adding a
# detector is one entry here plus a client and a parser.
class AiDetector
  class UnknownDetector < StandardError; end

  Definition = Struct.new(:vendor, :parser_class, :client_builder)

  REGISTRY = {
    RevisionAiScore::PANGRAM_V3_KEY =>
      Definition.new(:pangram, PangramResponseParser, -> { PangramApi.v3 }),
    RevisionAiScore::PANGRAM_V4_KEY =>
      Definition.new(:pangram, PangramResponseParser, -> { PangramApi.v4 }),
    RevisionAiScore::ORIGINALITY_LITE_102_KEY =>
      Definition.new(:originality, OriginalityResponseParser, -> { OriginalityApi.lite_102 }),
    RevisionAiScore::ORIGINALITY_TURBO_KEY =>
      Definition.new(:originality, OriginalityResponseParser, -> { OriginalityApi.turbo }),
    RevisionAiScore::ORIGINALITY_ACADEMIC_KEY =>
      Definition.new(:originality, OriginalityResponseParser, -> { OriginalityApi.academic }),
    RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY =>
      Definition.new(:originality, OriginalityResponseParser,
                     -> { OriginalityApi.ai_allowance(threshold: 15) }),
    RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY =>
      Definition.new(:originality, OriginalityResponseParser,
                     -> { OriginalityApi.ai_allowance(threshold: 40) })
  }.freeze

  def self.keys
    REGISTRY.keys
  end

  def self.registered?(key)
    REGISTRY.key?(key)
  end

  # Parser for a stored check_type, including historical keys that are no
  # longer selectable (e.g. 'Originality Lite 1.0.0'). Nil for unknown keys.
  def self.parser_class_for(check_type)
    return REGISTRY[check_type].parser_class if registered?(check_type)
    return PangramResponseParser if check_type.to_s.start_with?('Pangram')

    OriginalityResponseParser if check_type.to_s.start_with?('Originality')
  end

  # Detectors (and so their clients) are memoized per key, which also lets
  # specs stub one client per detector.
  def self.for(key)
    raise UnknownDetector, "no AI detector registered for #{key.inspect}" unless registered?(key)

    @detectors ||= {}
    @detectors[key] ||= new(key)
  end

  attr_reader :key

  def initialize(key)
    @key = key
    @definition = REGISTRY.fetch(key)
  end

  def vendor
    @definition.vendor
  end

  def pangram?
    vendor == :pangram
  end

  def client
    @client ||= @definition.client_builder.call
  end

  # Sends the text to the detector and returns a parser wrapping the raw response.
  def score(text)
    parse(client.inference(text))
  end

  # Wraps a raw response (fresh from the API or loaded from RevisionAiScore#details)
  # in this detector's parser.
  def parse(response)
    @definition.parser_class.new(key, response)
  end
end
