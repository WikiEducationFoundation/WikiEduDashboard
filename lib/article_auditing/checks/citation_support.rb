# frozen_string_literal: true

require 'digest'
require_dependency "#{Rails.root}/lib/article_auditing/llm_check"
require_dependency "#{Rails.root}/lib/article_auditing/citation_judge"
require_dependency "#{Rails.root}/lib/claim_verification/claim_citation_extractor"
require_dependency "#{Rails.root}/lib/claim_verification/source_fetcher"
require_dependency "#{Rails.root}/lib/claim_verification/host_throttle"

module ArticleAuditing
  module Checks
    # Whether each cited sentence is supported by the sources it cites. Every
    # source with a URL is fetched (falling back to its archive copy) and
    # judged against all the sentences that cite it; sources with no URL, such
    # as books, are listed as offline. The artifact has one row per sentence
    # and source; sentences that none of their readable sources support
    # become findings.
    #
    # Only the first `max_claims` cited sentences (in article order) are
    # checked, which bounds the cost of a long, heavily cited article; the
    # usage says how many were left out.
    #
    # Unlike the other LLM checks this doesn't use the article prompt cache:
    # its requests carry source text, not the article. Sources are fetched one
    # at a time, while earlier sources are being judged.
    # Prompt: config/article_audit/prompts/sourcing.citation_support.md
    class CitationSupport < LlmCheck
      KEY = 'sourcing.citation_support'
      CATEGORY = 'sourcing'
      JUDGE_CONCURRENCY = 3
      DEFAULT_MAX_CLAIMS = 100

      # Severity of the finding for a sentence that no source supports, keyed by
      # the best verdict among its sources, best first. Sentences whose only
      # verdicts are cannot_judge get no finding.
      FINDINGS = {
        'partially_supported' => 'suggestion',
        'contradicted' => 'should_fix',
        'not_supported' => 'should_fix',
        'wrong_source' => 'should_fix'
      }.freeze
      # The article_audit.citation_verdicts title for each verdict. A wrong
      # source doesn't cover the claim either; the explanation says the link
      # is wrong.
      TITLES = {
        'partially_supported' => 'partially_supported',
        'contradicted' => 'contradicted',
        'not_supported' => 'not_supported',
        'wrong_source' => 'not_supported'
      }.freeze

      def shares_article_cache?
        false
      end

      def version
        Digest::SHA256.hexdigest([prompt, schema.to_json, VERSION].join("\n")).first(12)
      end

      def schema
        CitationJudge::SCHEMA
      end

      def run(context)
        extraction = ::ClaimVerification::ClaimCitationExtractor.new(context.html)
        claims = capped_claims(extraction.claims)
        citations = extraction.citations.index_by(&:ref_id)
        results = check_sources(claims_by_citation(claims, citations))
        findings = findings_for(claims, results)
        unverified = QuoteValidator.new(context).mark!(findings)
        output(findings, artifacts: { claims: rows(claims, results) },
                         usage: usage(results).merge(
                           'claims' => claims.size, 'unverified_quotes' => unverified,
                           'claims_over_cap' => extraction.claims.size - claims.size
                         ))
      end

      private

      # { id => claim } for the first max_claims claims, numbered from 1.
      def capped_claims(claims)
        max = config.fetch('max_claims', DEFAULT_MAX_CLAIMS)
        claims.first(max).each_with_index.to_h { |claim, index| [index + 1, claim] }
      end

      # { citation => { id => claim } } for every citation some claim cites.
      def claims_by_citation(claims, citations)
        claims.each_with_object(Hash.new { |hash, key| hash[key] = {} }) do |(id, claim), grouped|
          claim.ref_ids.uniq.each do |ref_id|
            grouped[citations[ref_id]][id] = claim if citations[ref_id]
          end
        end
      end

      # { citation => { source:, judgment: or error: } }. Fetches run on this
      # thread, one after another; judgments run on a small pool meanwhile.
      def check_sources(grouped)
        pool = Concurrent::FixedThreadPool.new(JUDGE_CONCURRENCY)
        throttle = ::ClaimVerification::HostThrottle.new
        pending = grouped.to_h do |citation, claims|
          source = ::ClaimVerification::SourceFetcher.new(citation, throttle:).result
          [citation, { source:, future: judge_later(pool, citation, claims, source) }]
        end
        results = pending.transform_values { |entry| settle(entry) }
        raise_if_all_failed(results)
        results
      ensure
        pool&.shutdown
        pool&.wait_for_termination
      end

      def judge_later(pool, citation, claims, source)
        return unless source.fetched?
        Concurrent::Promises.future_on(pool) { judge.judge(claims, source, citation.cite_text) }
      end

      def settle(entry)
        future = entry[:future]
        return { source: entry[:source] } if future.nil?
        judgment = future.value
        return { source: entry[:source], error: future.reason } if future.rejected?
        { source: entry[:source], judgment: }
      end

      # A provider failure for every source (a bad API key, say) fails the
      # whole check, rather than succeeding with an error in every row.
      # Errors other than provider failures are bugs, and fail the check too.
      def raise_if_all_failed(results)
        errors = results.values.filter_map { |result| result[:error] }
        bug = errors.find { |error| !error.is_a?(Llm::Error) }
        raise bug if bug
        raise errors.first if errors.any? && results.values.none? { |result| result[:judgment] }
      end

      def judge
        @judge ||= CitationJudge.new(adapter:, prompt:, model:, effort:)
      end

      def rows(claims, results)
        claims.flat_map do |id, claim|
          results.filter_map do |citation, result|
            next unless claim.ref_ids.include?(citation.ref_id)
            row(claim, citation, result, id)
          end
        end
      end

      def row(claim, citation, result, id)
        verdict = result[:judgment]&.verdicts&.dig(id) || {}
        { 'claim' => claim.sentence, 'source' => citation.cite_text.to_s.truncate(200),
          'url' => result[:source].url, 'verdict' => verdict['verdict'] || status(result),
          'evidence' => verdict['quote'].presence,
          'explanation' => verdict['explanation'].presence }.merge(problems(result)).compact
      end

      def problems(result)
        { 'fetch_error' => result[:source].reason, 'judge_error' => result[:error]&.message,
          'truncated' => result[:judgment]&.truncated.presence }
      end

      # The outcome for a source that has no verdict for the claim.
      def status(result)
        return 'source_offline' if result[:source].status == :offline_source
        return 'source_inaccessible' unless result[:source].fetched?
        result[:error] ? 'error' : 'no_verdict'
      end

      def findings_for(claims, results)
        claims.filter_map do |id, claim|
          verdicts = results.filter_map { |_, result| result[:judgment]&.verdicts&.dig(id) }
          next if verdicts.any? { |verdict| verdict['verdict'] == 'supported' }
          best = FINDINGS.keys.lazy.filter_map { |name| verdict_named(verdicts, name) }.first
          claim_finding(claim, best) if best
        end
      end

      def verdict_named(verdicts, name)
        verdicts.find { |verdict| verdict['verdict'] == name }
      end

      def claim_finding(claim, verdict)
        name = verdict['verdict']
        title = I18n.t("article_audit.citation_verdicts.#{TITLES[name]}")
        finding(severity: FINDINGS[name], title:,
                explanation: verdict['explanation'], quote: claim.sentence, policy_refs: %w[WP:V])
      end

      def usage(results)
        totals = Hash.new(0)
        results.each_value do |result|
          result[:judgment]&.usage&.each { |name, value| totals[name] += value }
        end
        totals.merge('model' => model, 'sources' => results.size,
                     'sources_fetched' => results.count { |_, r| r[:source].fetched? })
      end
    end
  end
end
