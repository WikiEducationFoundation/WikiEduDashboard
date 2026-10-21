# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
require_dependency "#{Rails.root}/lib/ai/pangram_response_parser"
require_dependency "#{Rails.root}/lib/ai/originality_response_parser"

# Registry of the AI text detectors the Dashboard can call, keyed by the
# RevisionAiScore#check_type their results are stored under. Each entry pairs
# an API client (anything responding to #inference(text)) with the parser that
# turns the raw response into the shared DetectorSummary shape, and names the
# vendor whose operating policy applies. Adding a detector is one entry here
# plus a client and a parser; adding a vendor is one Vendor below.
class AiDetector
  class UnknownDetector < StandardError; end

  # Failures any detector call can hit regardless of vendor.
  TRANSPORT_ERRORS = [Faraday::Error, JSON::ParserError].freeze

  # Vendor-level operating policy, so nothing outside the registry has to know
  # which vendors exist: how a result is rendered on the admin page, the
  # vendor's minimum input, how a call is billed, how to read the remaining
  # balance, and which exceptions mean "this call failed" rather than "this
  # code is broken". Any field may be nil.
  Vendor = Struct.new(:name, :partial, :min_words, :credit_estimator, :balance_reader, :errors,
                      keyword_init: true) do
    def credit_balance
      balance_reader&.call
    end
  end

  PANGRAM = Vendor.new(name: :pangram, partial: 'ai_tools/pangram',
                       errors: [PangramApi::Error]).freeze
  ORIGINALITY_CREDITS = lambda do |word_counts|
    word_counts.sum { |words| words.fdiv(OriginalityApi::WORDS_PER_CREDIT).ceil }
  end
  # An allowance scan appears to bill as an AI check plus an allowance check.
  ALLOWANCE_CREDITS = ->(word_counts) { ORIGINALITY_CREDITS.call(word_counts) * 2 }
  ORIGINALITY = Vendor.new(name: :originality, partial: 'ai_tools/originality',
                           min_words: OriginalityApi::MIN_WORDS,
                           credit_estimator: ORIGINALITY_CREDITS,
                           balance_reader: -> { OriginalityApi.credit_balance },
                           errors: [OriginalityApi::Error]).freeze

  # credit_estimator here overrides the vendor's for one detector.
  Definition = Struct.new(:vendor, :parser_class, :client_builder, :credit_estimator,
                          keyword_init: true)

  def self.pangram(builder)
    Definition.new(vendor: PANGRAM, parser_class: PangramResponseParser, client_builder: builder)
  end

  def self.originality(builder, credit_estimator: nil)
    Definition.new(vendor: ORIGINALITY, parser_class: OriginalityResponseParser,
                   client_builder: builder, credit_estimator:)
  end

  REGISTRY = {
    RevisionAiScore::PANGRAM_V3_KEY => pangram(-> { PangramApi.v3 }),
    RevisionAiScore::PANGRAM_V4_KEY => pangram(-> { PangramApi.v4 }),
    RevisionAiScore::ORIGINALITY_LITE_102_KEY => originality(-> { OriginalityApi.lite_102 }),
    RevisionAiScore::ORIGINALITY_TURBO_KEY => originality(-> { OriginalityApi.turbo }),
    RevisionAiScore::ORIGINALITY_ACADEMIC_KEY => originality(-> { OriginalityApi.academic }),
    RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_15_KEY =>
      originality(-> { OriginalityApi.ai_allowance(threshold: 15) },
                  credit_estimator: ALLOWANCE_CREDITS),
    RevisionAiScore::ORIGINALITY_AI_ALLOWANCE_40_KEY =>
      originality(-> { OriginalityApi.ai_allowance(threshold: 40) },
                  credit_estimator: ALLOWANCE_CREDITS)
  }.freeze

  def self.keys
    REGISTRY.keys
  end

  def self.registered?(key)
    REGISTRY.key?(key)
  end

  def self.vendors
    REGISTRY.values.map(&:vendor).uniq
  end

  # Every exception class that means a detector call failed and should be
  # recorded or shown rather than raised: vendor errors plus transport failures.
  def self.recoverable_errors
    TRANSPORT_ERRORS + vendors.flat_map(&:errors)
  end

  # Remaining credit per vendor that can report one, keyed like
  # 'originality_credit_balance'. A failed lookup yields the error message.
  def self.credit_balances(detectors)
    detectors.map(&:vendor).uniq.filter_map do |vendor|
      next unless vendor.balance_reader

      balance = begin
        vendor.credit_balance
      rescue *recoverable_errors => e
        e.message
      end
      ["#{vendor.name}_credit_balance", balance]
    end.to_h
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
    vendor.name == :pangram
  end

  # View partial that renders this detector's raw result.
  def partial
    vendor.partial
  end

  # Fewest words the vendor will score; nil when there is no floor.
  def min_words
    vendor.min_words
  end

  def error_classes
    vendor.errors
  end

  # Credits the vendor would bill for scoring texts of these word counts, or
  # nil when the vendor is not metered this way.
  def estimated_credits(word_counts)
    (@definition.credit_estimator || vendor.credit_estimator)&.call(word_counts)
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
