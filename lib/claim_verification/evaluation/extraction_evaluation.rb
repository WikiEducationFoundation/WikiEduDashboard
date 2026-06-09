# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"

module ClaimVerification
  module Evaluation
    # Scores claim/citation extraction against a labeled dataset, so
    # changes to the extraction heuristics (or alternative extractor
    # implementations) can be compared on the same cases.
    #
    # Console usage:
    #   eval = ClaimVerification::Evaluation::ExtractionEvaluation.new
    #   eval.summary       # => { claim_precision: 1.0, claim_recall: 1.0, ... }
    #   eval.case_results  # => per-case matched/missing/unexpected detail
    #
    # Dataset format (YAML, html files relative to the dataset file):
    #   - name: third_place_diff
    #     html_file: third_place_diff.html
    #     claims:
    #       - sentence_includes: privilege certain social groups
    #         ref_ids: [cite_note-1]
    #     citations:
    #       - ref_id: cite_note-1
    #         text_includes: Putnam
    class ExtractionEvaluation
      DEFAULT_DATASET =
        "#{Rails.root}/fixtures/claim_verification_eval/extraction_cases.yml"

      attr_reader :case_results, :summary

      def initialize(dataset_path: DEFAULT_DATASET,
                     extractor_class: ClaimCitationExtractor)
        @dataset_path = dataset_path
        @extractor_class = extractor_class
        evaluate
      end

      private

      def evaluate
        cases = YAML.safe_load_file(@dataset_path)
        @case_results = cases.map { |kase| evaluate_case(kase) }
        @summary = summarize
      end

      def evaluate_case(kase)
        html_path = File.expand_path(kase['html_file'], File.dirname(@dataset_path))
        extractor = @extractor_class.new(File.read(html_path))
        {
          name: kase['name'],
          claims: match_claims(kase['claims'] || [], extractor.claims),
          citations: match_citations(kase['citations'] || [], extractor.citations)
        }
      end

      # Each expected claim may match one extracted claim; extracted
      # claims left over count against precision as unexpected.
      def match_claims(expected, extracted)
        unmatched = extracted.dup
        missing = expected.reject do |expectation|
          found = unmatched.find { |claim| claim_match?(expectation, claim) }
          unmatched.delete(found) if found
        end
        { expected: expected.size, extracted: extracted.size,
          matched: expected.size - missing.size,
          missing: missing.map { |m| m['sentence_includes'] },
          unexpected: unmatched.map(&:sentence) }
      end

      def claim_match?(expectation, claim)
        claim.sentence.include?(expectation['sentence_includes']) &&
          claim.ref_ids.sort == expectation['ref_ids'].sort
      end

      def match_citations(expected, extracted)
        missing = expected.reject do |expectation|
          extracted.find { |citation| citation_match?(expectation, citation) }
        end
        { expected: expected.size, extracted: extracted.size,
          matched: expected.size - missing.size,
          missing: missing.map { |m| m['ref_id'] } }
      end

      def citation_match?(expectation, citation)
        citation.ref_id == expectation['ref_id'] &&
          citation.cite_text.include?(expectation.fetch('text_includes', ''))
      end

      def summarize
        matched = total(:claims, :matched)
        precision = ratio(matched, total(:claims, :extracted))
        recall = ratio(matched, total(:claims, :expected))
        { claim_precision: precision, claim_recall: recall,
          claim_f1: f1(precision, recall),
          citation_recall: ratio(total(:citations, :matched),
                                 total(:citations, :expected)) }
      end

      def total(section, field)
        @case_results.sum { |result| result[section][field] }
      end

      def ratio(numerator, denominator)
        return 0.0 if denominator.zero?
        (numerator / denominator.to_f).round(3)
      end

      def f1(precision, recall)
        return 0.0 if (precision + recall).zero?
        (2 * precision * recall / (precision + recall)).round(3)
      end
    end
  end
end
