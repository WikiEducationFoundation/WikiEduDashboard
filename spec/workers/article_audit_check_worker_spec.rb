# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"
require "#{Rails.root}/lib/article_auditing/registry"

describe ArticleAuditCheckWorker do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:audit) { ArticleAudit.create!(wiki:, mw_rev_id: 123, status: 'partial') }
  let(:context) do
    instance_double(ArticleAuditing::Context,
                    parsed_wikitext: ArticleAuditing::Wikitext.new("Fact.<ref>x</ref>\n{{reflist}}"))
  end

  before do
    allow(ArticleAuditing::Context).to receive(:new).and_return(context)
    allow(context).to receive(:preload).and_return(context)
    audit.check_results.create!(check_key: 'sourcing.reference_list', status: 'failed', error: 'x')
  end

  it 'adds a new result for the check and recomputes the audit status' do
    described_class.new.perform(audit.id, 'sourcing.reference_list')
    expect(audit.check_results.count).to eq(2)
    expect(audit.latest_check_results.first).to be_succeeded
    expect(audit.reload.status).to eq(ArticleAudit::COMPLETE)
  end
end
