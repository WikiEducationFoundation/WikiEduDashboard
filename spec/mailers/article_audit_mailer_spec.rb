# frozen_string_literal: true

require 'rails_helper'

describe ArticleAuditMailer do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:requester) { create(:admin, email: 'admin@example.com') }
  let(:audit) do
    ArticleAudit.create!(wiki:, mw_rev_id: 123, article_title: 'Acme', requester:,
                         status: ArticleAudit::COMPLETE)
  end

  it 'emails the requester a link to the report' do
    mail = described_class.report_ready(audit)
    expect(mail.to).to eq(['admin@example.com'])
    expect(mail.body.encoded).to include("/article_audits/#{audit.id}")
  end

  it 'names the article and status' do
    mail = described_class.report_ready(audit)
    expect(mail.subject).to eq('Article Audit: Acme')
    expect(mail.body.encoded).to include('Acme', 'Complete')
  end

  it 'sends nothing when email is disabled' do
    allow(Features).to receive(:email?).and_return(false)
    expect { described_class.send_report_ready(audit) }
      .not_to(change { ActionMailer::Base.deliveries.count })
  end

  it 'sends when email is enabled' do
    allow(Features).to receive(:email?).and_return(true)
    expect { described_class.send_report_ready(audit) }
      .to change { ActionMailer::Base.deliveries.count }.by(1)
  end
end
