# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/context"
require_dependency "#{Rails.root}/lib/article_auditing/registry"
require_dependency "#{Rails.root}/lib/article_auditing/check_runner"
require_dependency "#{Rails.root}/lib/article_auditing/llm_check"
require_dependency "#{Rails.root}/lib/article_auditing/rendered_article"

# Runs every enabled check for an ArticleAudit and records the outcome.
#
# Deterministic checks run first, in config order. LLM checks share the
# article as a cached prompt prefix: the first one runs alone so it writes the
# cache, then the rest run in parallel and read it. LLM checks that don't use
# that prefix (citation support, which sends cited sources instead) start
# straight away, since they are the slowest. (The parallelism is against the
# LLM provider only; Wikimedia fetches all happen up front, sequentially, in
# Context#preload.)
#
# A check that fails doesn't stop the others; the audit ends up PARTIAL. If
# the revision can't be fetched at all, the audit is FAILED.
class RunArticleAudit
  LLM_CONCURRENCY = 4

  attr_reader :audit

  def initialize(audit, checks: ArticleAuditing::Registry.enabled_checks)
    @audit = audit
    @checks = checks
    perform
  end

  private

  def perform
    @audit.update!(status: ArticleAudit::RUNNING, started_at: Time.zone.now, error: nil)
    @context = ArticleAuditing::Context.new(wiki: @audit.wiki, mw_rev_id: @audit.mw_rev_id)
    return fail_audit('revision not found') unless load_revision

    run_checks
    finish
  end

  def load_revision
    return false if @context.revision_info.nil?
    @context.preload
    @audit.update!(article_title: @context.title, namespace: @context.namespace,
                   mw_page_id: @context.page_id)
    ArticleAuditing::RenderedArticle.store(@context)
    true
  end

  def run_checks
    applicable = @checks.select { |check| applies?(check) }
    llm_checks, other_checks = applicable.partition { |check| check.is_a?(ArticleAuditing::LlmCheck) }
    runner = ArticleAuditing::CheckRunner.new(audit: @audit, context: @context)
    other_checks.each { |check| runner.run(check) }
    run_llm_checks(llm_checks, runner)
  end

  # A check whose applicability test fails is run anyway, so that the error
  # it hits is recorded on its own result row instead of stopping the audit.
  def applies?(check)
    check.applies_to?(@context)
  rescue StandardError
    true
  end

  def run_llm_checks(checks, runner)
    return if checks.empty?
    sharing, independent = checks.partition(&:shares_article_cache?)
    pool = Concurrent::FixedThreadPool.new(LLM_CONCURRENCY)
    independent.each { |check| post(pool, runner, check) }
    runner.run(sharing.first) if sharing.any?
    sharing.drop(1).each { |check| post(pool, runner, check) }
    pool.shutdown
    pool.wait_for_termination
  end

  def post(pool, runner, check)
    pool.post { ActiveRecord::Base.connection_pool.with_connection { runner.run(check) } }
  end

  def finish
    @audit.check_results.reset
    @audit.finalize!
    ArticleAuditMailer.send_report_ready(@audit)
  end

  def fail_audit(error)
    @audit.update!(status: ArticleAudit::FAILED, error:, completed_at: Time.zone.now)
    ArticleAuditMailer.send_report_ready(@audit)
  end
end
