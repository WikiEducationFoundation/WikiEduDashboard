# frozen_string_literal: true

require_dependency "#{Rails.root}/app/services/run_article_audit"

# Runs an ArticleAudit in the background. Every LLM check is billed, so the
# job is not retried: RunArticleAudit records per-check failures itself, and
# a failed check can be re-run on its own (ArticleAuditCheckWorker) without
# paying for the whole audit again.
class ArticleAuditWorker
  include Sidekiq::Worker
  # Off the default queue, whose production process runs one job at a time and
  # carries the AI edit alert checks; an audit can take minutes.
  sidekiq_options queue: 'report_csv', lock: :until_executed, retry: 0

  def self.run(audit)
    perform_async(audit.id)
  end

  def perform(audit_id)
    audit = ArticleAudit.find_by(id: audit_id)
    return if audit.nil?
    RunArticleAudit.new(audit)
  rescue StandardError => e
    audit&.update(status: ArticleAudit::FAILED, error: "#{e.class}: #{e.message}",
                  completed_at: Time.zone.now)
    raise e
  end
end
