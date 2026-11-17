# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/check"
require_dependency "#{Rails.root}/lib/ai/ai_detector"

module ArticleAuditing
  module Checks
    # Scores the revision's prose with Pangram, the same detector used for
    # production AI edit alerts, and flags it at the same threshold. The score
    # is also recorded as a RevisionAiScore (check_origin 'article_audit') so
    # it shows up alongside the Dashboard's other AI checks.
    class AiDetection < Check
      KEY = 'external.ai_detection'
      CATEGORY = 'external'
      # Same detector, minimum length and threshold as CheckRevisionWithPangram.
      DETECTOR_KEY = CheckRevisionWithPangram::DETECTOR_KEY
      MIN_TEXT_LENGTH = CheckRevisionWithPangram::MIN_PLAIN_TEXT_LENGTH
      AI_LIKELY_THRESHOLD = 0.9

      def engine
        "pangram:#{DETECTOR_KEY}"
      end

      # Skipped where the Dashboard has no Pangram key.
      def applies_to?(_context)
        ENV['pangram_api_key'].present?
      end

      def run(context)
        text = context.prose_text
        return output([], usage: { 'skipped' => 'text too short' }) if text.length < MIN_TEXT_LENGTH

        parser = detector.score(text)
        score = record_score(context, parser)
        output(findings(parser), artifacts: { 'ai_detection' => summary(parser, score) },
                                 usage: { 'characters' => text.length })
      end

      private

      def detector
        AiDetector.for(DETECTOR_KEY)
      end

      def findings(parser)
        return [] unless parser.max_ai_likelihood > AI_LIKELY_THRESHOLD
        [finding(severity: 'must_fix',
                 **coded(:ai_likely, max: (parser.max_ai_likelihood * 100).round),
                 policy_refs: %w[WP:LLM])]
      end

      def record_score(context, parser)
        RevisionAiScore.create!(revision_id: context.mw_rev_id, wiki_id: context.wiki.id,
                                avg_ai_likelihood: parser.average_ai_likelihood,
                                max_ai_likelihood: parser.max_ai_likelihood,
                                details: parser.clean_result, check_type: DETECTOR_KEY,
                                check_origin: RevisionAiScore::ARTICLE_AUDIT_ORIGIN)
      end

      def summary(parser, score)
        details = parser.pangram_details
        {
          'headline' => details[:headline_result],
          'average_ai_likelihood' => parser.average_ai_likelihood.round(3),
          'max_ai_likelihood' => parser.max_ai_likelihood.round(3),
          'fraction_ai' => details[:fraction_ai_content],
          'share_link' => details[:pangram_share_link],
          'revision_ai_score_id' => score.id
        }
      end
    end
  end
end
