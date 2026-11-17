# frozen_string_literal: true

# Tells the person who requested an Article Audit that it has finished.
class ArticleAuditMailer < ApplicationMailer
  def self.send_report_ready(audit)
    return unless Features.email?
    return if audit.requester&.email.blank?
    report_ready(audit).deliver_now
  end

  def report_ready(audit)
    @audit = audit
    @report_link = "https://#{ENV['dashboard_url']}/article_audits/#{audit.id}"
    mail(to: audit.requester.email,
         subject: "#{I18n.t('article_audit.heading')}: #{audit.article_title}")
  end
end
