# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/llm/errors"

module ArticleAuditing
  # Runs one check against a context and records the outcome as a new
  # ArticleAuditCheckResult. A failing check never raises: its error is
  # stored on the result row so the rest of the audit carries on and the
  # check can be re-run later.
  class CheckRunner
    def initialize(audit:, context:)
      @audit = audit
      @context = context
    end

    def run(check)
      # Created by id rather than through @audit.check_results, because checks
      # may run on several threads and the association cache isn't thread-safe.
      result = ArticleAuditCheckResult.create!(article_audit_id: @audit.id, check_key: check.key,
                                               check_version: check.version, engine: check.engine,
                                               status: ArticleAuditCheckResult::RUNNING)
      started = monotonic_ms
      record_output(result, check.run(@context))
    rescue Llm::Error => e
      record_failure(result, e, level: 'warning')
    rescue StandardError => e
      record_failure(result, e, level: 'error')
    ensure
      result&.update!(duration_ms: monotonic_ms - started) if started
    end

    private

    def record_output(result, output)
      result.update!(status: ArticleAuditCheckResult::SUCCEEDED, findings: output.findings,
                     artifacts: output.artifacts, usage: output.usage)
      result
    end

    def record_failure(result, error, level:)
      Sentry.capture_exception(error, level:, extra: { article_audit_id: @audit.id,
                                                       check: result&.check_key })
      result&.update!(status: ArticleAuditCheckResult::FAILED,
                      error: "#{error.class}: #{error.message}")
      result
    end

    def monotonic_ms
      Process.clock_gettime(Process::CLOCK_MONOTONIC, :millisecond)
    end
  end
end
