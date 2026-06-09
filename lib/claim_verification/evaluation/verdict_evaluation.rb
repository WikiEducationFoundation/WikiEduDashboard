# frozen_string_literal: true

module ClaimVerification
  module Evaluation
    # Scores a claim verifier against a labeled dataset of claim/source
    # pairs. The verifier is any callable taking (claim:, source_text:)
    # and returning either a verdict string/symbol or an object that
    # responds to #verdict — so an LLM-backed judge, a deterministic
    # one, or judges on different models/providers can all be compared
    # on the same cases.
    #
    # Console usage:
    #   verifier = ->(claim:, source_text:) do
    #     VerifyClaimAgainstSource.new(claim:, source_text:).verdict
    #   end
    #   eval = ClaimVerification::Evaluation::VerdictEvaluation.new(verifier)
    #   eval.summary  # => { total: 8, correct: 7, accuracy: 0.875, confusion: {...} }
    #
    # Dataset format (YAML):
    #   - name: supported_simple
    #     claim: The tower is 330 metres tall.
    #     source_text: ...text of the cited source...
    #     expected_verdict: supported
    class VerdictEvaluation
      DEFAULT_DATASET =
        "#{Rails.root}/fixtures/claim_verification_eval/verdict_cases.yml"

      attr_reader :case_results, :summary

      def initialize(verifier, dataset_path: DEFAULT_DATASET)
        @verifier = verifier
        @dataset_path = dataset_path
        evaluate
      end

      private

      def evaluate
        cases = YAML.safe_load_file(@dataset_path)
        @case_results = cases.map { |kase| evaluate_case(kase) }
        @summary = summarize
      end

      def evaluate_case(kase)
        result = @verifier.call(claim: kase['claim'],
                                source_text: kase['source_text'])
        verdict = (result.respond_to?(:verdict) ? result.verdict : result).to_s
        { name: kase['name'],
          expected: kase['expected_verdict'],
          actual: verdict,
          correct: verdict == kase['expected_verdict'] }
      end

      def summarize
        correct = @case_results.count { |result| result[:correct] }
        { total: @case_results.size,
          correct:,
          accuracy: accuracy(correct),
          confusion: confusion_matrix }
      end

      def accuracy(correct)
        return 0.0 if @case_results.empty?
        (correct / @case_results.size.to_f).round(3)
      end

      # { expected_verdict => { actual_verdict => count } }
      def confusion_matrix
        @case_results.group_by { |result| result[:expected] }
                     .transform_values do |results|
          results.group_by { |result| result[:actual] }
                 .transform_values(&:size)
        end
      end
    end
  end
end
