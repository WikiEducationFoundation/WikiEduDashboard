# frozen_string_literal: true

require_dependency "#{Rails.root}/lib/article_auditing/context"
require_dependency "#{Rails.root}/lib/article_auditing/registry"
require_dependency "#{Rails.root}/lib/article_auditing/check_runner"

# Re-runs a single check for an existing ArticleAudit, adding a new result row
# alongside the earlier ones. Used to retry a failed check, or to try a check
# again after changing its prompt or engine.
class ArticleAuditCheckWorker
  include Sidekiq::Worker
  # Off the default queue, whose production process runs one job at a time and
  # carries the AI edit alert checks; a re-run check can take minutes.
  sidekiq_options queue: 'report_csv', lock: :until_executed, retry: 0

  def self.rerun(audit, check_key)
    audit.update!(status: ArticleAudit::RUNNING)
    perform_async(audit.id, check_key)
  end

  def perform(audit_id, check_key)
    audit = ArticleAudit.find_by(id: audit_id)
    return if audit.nil?
    context = ArticleAuditing::Context.new(wiki: audit.wiki, mw_rev_id: audit.mw_rev_id).preload
    ArticleAuditing::CheckRunner.new(audit:, context:).run(ArticleAuditing::Registry.check(check_key))
  ensure
    audit&.finalize!
  end
end
