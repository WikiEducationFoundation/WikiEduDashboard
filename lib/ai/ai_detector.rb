# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/pangram_api"
require_dependency "#{Rails.root}/lib/originality_api"
require_dependency "#{Rails.root}/lib/ai/pangram_response_parser"
require_dependency "#{Rails.root}/lib/ai/originality_response_parser"
require_dependency "#{Rails.root}/lib/ai/originality_5_response_parser"

# Registry of the AI text detectors the Dashboard can call, keyed by the
# RevisionAiScore#check_type their results are stored under. Each entry pairs
# an API client (anything responding to #inference(text)) with the parser that
# turns the raw response into the shared DetectorSummary shape, and names the
# vendor whose operating policy applies. Adding a detector is one entry here
# plus a client and a parser; adding a vendor is one Vendor below. Retiring a
# detector is removing its entry: stored rows keep parsing through
# parser_class_for.
class AiDetector
  class UnknownDetector < StandardError; end

  # Failures any detector call can hit regardless of vendor.
  TRANSPORT_ERRORS = [Faraday::Error, JSON::ParserError].freeze

  # Vendor-level operating policy, so nothing outside the registry has to know
  # which vendors exist: how a result is rendered on the admin page, the
  # vendor's minimum input, how a call is billed, how to read the remaining
  # balance, which exceptions mean "this call failed" rather than "this code is
  # broken", and which of those mean the vendor now serves a different model than
  # the detector is pinned to. Any field may be nil.
  Vendor = Struct.new(:name, :partial, :min_words, :credit_estimator, :balance_reader, :errors,
                      :model_mismatch_errors, keyword_init: true) do
    def credit_balance
      balance_reader&.call
    end
  end

  PANGRAM = Vendor.new(name: :pangram, partial: 'ai_tools/pangram',
                       errors: [PangramApi::Error],
                       model_mismatch_errors: [PangramApi::ModelMismatch]).freeze
  ORIGINALITY_CREDITS = lambda do |word_counts|
    word_counts.sum { |words| words.fdiv(OriginalityApi::WORDS_PER_CREDIT).ceil }
  end
  ORIGINALITY = Vendor.new(name: :originality, partial: 'ai_tools/originality',
                           min_words: OriginalityApi::MIN_WORDS,
                           credit_estimator: ORIGINALITY_CREDITS,
                           balance_reader: -> { OriginalityApi.credit_balance },
                           errors: [OriginalityApi::Error],
                           model_mismatch_errors: [OriginalityApi::ModelMismatch]).freeze

  # credit_estimator here overrides the vendor's for one detector. A detector
  # that is not selectable is called only by code that names it (production
  # alerting); the admin AI tools page and comparison scoring do not offer it.
  Definition = Struct.new(:vendor, :parser_class, :client_builder, :credit_estimator,
                          :selectable, keyword_init: true)

  def self.pangram(builder, selectable: true)
    Definition.new(vendor: PANGRAM, parser_class: PangramResponseParser, client_builder: builder,
                   selectable:)
  end

  def self.originality(builder, credit_estimator: nil)
    Definition.new(vendor: ORIGINALITY, parser_class: Originality5ResponseParser,
                   client_builder: builder, credit_estimator:, selectable: true)
  end

  REGISTRY = {
    # Production alerting (CheckRevisionWithPangram): whatever version pangram-4 serves.
    RevisionAiScore::PANGRAM_V4_KEY => pangram(-> { PangramApi.v4 }, selectable: false),
    RevisionAiScore::PANGRAM_V4_1_KEY => pangram(-> { PangramApi.v4(expected_version: '4.1') }),
    RevisionAiScore::ORIGINALITY_5_KEY => originality(-> { OriginalityApi.model_5 }),
    RevisionAiScore::ORIGINALITY_5_MAX_KEY => originality(-> { OriginalityApi.model_5_max })
  }.freeze

  # Detectors offered on the admin AI tools page and for comparison scoring.
  def self.keys
    REGISTRY.select { |_key, definition| definition.selectable }.keys
  end

  def self.registered?(key)
    REGISTRY.key?(key)
  end

  def self.selectable?(key)
    keys.include?(key)
  end

  def self.vendors
    REGISTRY.values.map(&:vendor).uniq
  end

  # Every exception class that means a detector call failed and should be
  # recorded or shown rather than raised: vendor errors plus transport failures.
  def self.recoverable_errors
    TRANSPORT_ERRORS + vendors.flat_map(&:errors)
  end

  # The vendor now serves a different model than a pinned detector expects. Every
  # further call would bill for a result that cannot be stored, so batch scoring
  # stops on these rather than recording them as failed units.
  def self.model_mismatch_errors
    vendors.flat_map { |vendor| vendor.model_mismatch_errors.to_a }
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

  # Parser for a stored check_type, including retired keys (e.g. 'Pangram 3',
  # 'Originality AI Allowance 40'), whose rows use the classic Originality shape.
  # Nil for unknown keys.
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
