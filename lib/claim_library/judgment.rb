# frozen_string_literal: true

module ClaimLibrary
  # A person's verdict on one claim against the source they read.
  #
  # The verdicts are the ones the fact-verification exercise offers students
  # (config/claim_verification_exercise.yml), so library records and student
  # responses can be compared directly. The flags name the ways a claim can go
  # wrong while still citing a real, relevant source; a judgment may carry any
  # number of them.
  class Judgment
    VERDICTS = %w[full_support partial_support unsupported contradicted undetermined].freeze

    FLAGS = %w[
      fabricated_quotation misattribution time_drift prediction_as_fact
      opinion_as_reporting single_case_generalised circular_citation
      dead_or_bare_link true_but_unsupported
    ].freeze

    attr_reader :verdict, :reason, :passage, :flags, :annotator, :judged_at

    def initialize(verdict:, reason:, annotator:, passage: nil, flags: [], judged_at: nil)
      @verdict = verdict.to_s
      @reason = reason.to_s.strip
      @annotator = annotator.to_s.strip
      @passage = passage.to_s.strip
      @flags = Array(flags).map(&:to_s)
      @judged_at = judged_at || Time.zone.now
    end

    def self.from_h(hash)
      return if hash.nil?
      hash = hash.transform_keys(&:to_s)
      judged_at = hash['judged_at'] && Time.zone.parse(hash['judged_at'])
      new(verdict: hash['verdict'], reason: hash['reason'], annotator: hash['annotator'],
          passage: hash['passage'], flags: hash['flags'], judged_at:)
    end

    # `ai_assisted` is written here as false and never read from input: the
    # only way to put a judgment in the library is through this class, and
    # the library holds human judgments only.
    def to_h
      { 'verdict' => verdict, 'reason' => reason, 'passage' => passage,
        'flags' => flags, 'annotator' => annotator,
        'judged_at' => judged_at.iso8601, 'ai_assisted' => false }
    end

    # Why this judgment cannot be recorded, or an empty list when it can.
    # `source_text` is the text the annotator read, used to confirm that the
    # quoted passage really is in it.
    def errors(source_text: nil)
      field_errors + passage_errors(source_text)
    end

    private

    def field_errors
      errors = []
      errors << "verdict must be one of: #{VERDICTS.join(', ')}" unless VERDICTS.include?(verdict)
      errors << 'reason is required' if reason.empty?
      errors << 'annotator is required' if annotator.empty?
      unknown = flags - FLAGS
      errors << "unknown flags: #{unknown.join(', ')}" if unknown.any?
      errors
    end

    # A verdict other than "undetermined" rests on something the source says,
    # so it must quote it, and the quotation must be real.
    def passage_errors(source_text)
      if passage.empty?
        return [] if verdict == 'undetermined'
        return ['passage is required unless the verdict is undetermined']
      end
      return [] if squeeze(source_text).include?(squeeze(passage))
      ['passage was not found in the source text']
    end

    def squeeze(text)
      text.to_s.gsub(/\s+/, ' ').strip
    end
  end
end
