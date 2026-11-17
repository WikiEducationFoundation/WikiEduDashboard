# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/article_audit_mailer

require_relative 'mailer_preview_helpers'

class ArticleAuditMailerPreview < ActionMailer::Preview
  include MailerPreviewHelpers

  DESCRIPTION = 'Sent to the person who requested an Article Audit when the report is ready.'
  METHOD_DESCRIPTIONS = {
    report_ready: 'Article Audit finished'
  }.freeze
  RECIPIENTS = 'audit requester'

  def report_ready
    ArticleAuditMailer.report_ready(example_audit)
  end

  private

  def example_audit
    ArticleAudit.new(id: 1, mw_rev_id: 1_234_567,
                     article_title: 'Selfie', status: ArticleAudit::COMPLETE,
                     requester: example_instructor)
  end
end
