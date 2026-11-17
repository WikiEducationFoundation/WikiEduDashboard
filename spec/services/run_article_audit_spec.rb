# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe RunArticleAudit do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:audit) { ArticleAudit.create!(wiki:, mw_rev_id: 123, requester: create(:admin)) }
  let(:revision_info) { { title: 'Acme', namespace: 0, page_id: 77, parent_id: 5 } }
  let(:context) do
    instance_double(ArticleAuditing::Context,
                    revision_info:, title: 'Acme', namespace: 0, page_id: 77,
                    parsed_wikitext: ArticleAuditing::Wikitext.new("'''Acme''' is great."),
                    wikitext: "'''Acme''' is great.", plaintext: 'Acme is great.',
                    llm_system_blocks: [{ text: 'article', cache: true }])
  end
  let(:adapter) { instance_double(Llm::AnthropicAdapter) }
  let(:llm_response) do
    Llm::Response.new(text: '{}', json: { 'findings' => [] }, model: 'claude-opus-5-5',
                      usage: { 'input_tokens' => 10, 'output_tokens' => 5 })
  end
  let(:checks) do
    [ArticleAuditing::Checks::ReferenceList.new, ArticleAuditing::Checks::UnsourcedClaims.new,
     ArticleAuditing::Checks::Tone.new]
  end

  before do
    allow(ArticleAuditing::Context).to receive(:new).and_return(context)
    allow(context).to receive(:preload).and_return(context)
    allow(Llm::Client).to receive(:adapter).and_return(adapter)
    allow(ArticleAuditMailer).to receive(:send_report_ready)
    allow(ArticleAuditing::RenderedArticle).to receive(:store)
  end

  context 'when every check succeeds' do
    before { allow(adapter).to receive(:complete).and_return(llm_response) }

    it 'records a result per check, completes, totals usage and sends mail' do
      described_class.new(audit, checks:)
      audit.reload
      expect(audit.status).to eq(ArticleAudit::COMPLETE)
      expect(audit.article_title).to eq('Acme')
      expect(audit.mw_page_id).to eq(77)
      expect(ArticleAuditing::RenderedArticle).to have_received(:store).with(context)
      expect(audit.check_results.map(&:check_key))
        .to contain_exactly('sourcing.reference_list', 'sourcing.unsourced_claims', 'tone')
      expect(audit.check_results).to all(be_succeeded)
      expect(audit.usage['anthropic:claude-opus-5-5']).to include('input_tokens' => 20)
      expect(ArticleAuditMailer).to have_received(:send_report_ready).with(audit)
    end

    it 'runs LLM checks that do not share the article cache' do
      allow(context).to receive(:html).and_return('<p>Acme is great.</p>')
      check_list = [ArticleAuditing::Checks::CitationSupport.new, *checks]
      described_class.new(audit, checks: check_list)
      expect(audit.check_results.find_by(check_key: 'sourcing.citation_support')).to be_succeeded
      expect(audit.reload.status).to eq(ArticleAudit::COMPLETE)
    end

    it 'stores deterministic findings' do
      described_class.new(audit, checks:)
      result = audit.check_results.find_by(check_key: 'sourcing.reference_list')
      expect(result.findings.first['severity']).to eq('must_fix')
      expect(result.engine).to eq('deterministic')
    end
  end

  context 'when an LLM check fails' do
    before do
      allow(adapter).to receive(:complete) do |user:, **|
        raise Llm::RetryableError, 'overloaded' if user.include?('Check: tone')
        llm_response
      end
    end

    it 'records the failure and marks the audit partial' do
      described_class.new(audit, checks:)
      expect(audit.reload.status).to eq(ArticleAudit::PARTIAL)
      failed = audit.check_results.find_by(check_key: 'tone')
      expect(failed).to be_failed
      expect(failed.error).to include('overloaded')
    end
  end

  context 'when a check raises while deciding whether it applies' do
    let(:broken_check) { ArticleAuditing::Checks::ReferenceList.new }
    let(:checks) { [broken_check, ArticleAuditing::Checks::Tone.new] }

    before do
      allow(adapter).to receive(:complete).and_return(llm_response)
      allow(broken_check).to receive(:applies_to?).and_raise(NoMethodError, 'boom')
      allow(broken_check).to receive(:run).and_raise(NoMethodError, 'boom')
    end

    it 'records that check as failed and runs the rest' do
      described_class.new(audit, checks:)
      expect(audit.reload.status).to eq(ArticleAudit::PARTIAL)
      expect(audit.check_results.find_by(check_key: 'tone')).to be_succeeded
      expect(audit.check_results.find_by(check_key: 'sourcing.reference_list').error)
        .to include('boom')
    end
  end

  context 'when the revision does not exist' do
    let(:revision_info) { nil }

    it 'fails the audit without running checks' do
      described_class.new(audit, checks:)
      expect(audit.reload.status).to eq(ArticleAudit::FAILED)
      expect(audit.check_results).to be_empty
      expect(ArticleAuditMailer).to have_received(:send_report_ready)
    end
  end
end
