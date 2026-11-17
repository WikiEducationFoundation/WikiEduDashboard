# frozen_string_literal: true

require 'rails_helper'

describe CreateArticleAudit do
  let(:admin) { create(:admin) }

  before { allow(ArticleAuditWorker).to receive(:run) }

  it 'audits the revision in a permanent link and queues the audit' do
    creator = described_class.new(url: 'https://en.wikipedia.org/w/index.php?title=Selfie&oldid=555',
                                  requester: admin)
    expect(creator.audit).to have_attributes(mw_rev_id: 555, article_title: 'Selfie',
                                             requester: admin, status: 'queued')
    expect(ArticleAuditWorker).to have_received(:run).with(creator.audit)
  end

  it 'leaves the audit unqueued when asked not to enqueue it' do
    creator = described_class.new(url: 'https://en.wikipedia.org/w/index.php?title=Selfie&oldid=555',
                                  requester: nil, enqueue: false)
    expect(creator.audit).to have_attributes(mw_rev_id: 555, status: 'queued')
    expect(ArticleAuditWorker).not_to have_received(:run)
  end

  it 'audits the newer revision of a diff' do
    creator = described_class.new(url: 'https://en.wikipedia.org/w/index.php?diff=900&oldid=800',
                                  requester: admin)
    expect(creator.audit.mw_rev_id).to eq(900)
  end

  it 'audits the latest revision of a page URL' do
    allow_any_instance_of(WikiApi::ArticleContent).to receive(:latest_revision_id)
      .with('Selfie').and_return(4242)
    creator = described_class.new(url: 'https://en.wikipedia.org/wiki/Selfie', requester: admin)
    expect(creator.audit.mw_rev_id).to eq(4242)
  end

  it 'links a tracked article with the same title' do
    wiki = Wiki.get_or_create(language: 'en', project: 'wikipedia')
    article = create(:article, title: 'Selfie', wiki:)
    creator = described_class.new(url: 'https://en.wikipedia.org/w/index.php?title=Selfie&oldid=1',
                                  requester: admin)
    expect(creator.audit.article).to eq(article)
  end

  it 'rejects a URL that is not on a wiki' do
    creator = described_class.new(url: 'https://example.com/foo', requester: admin)
    expect(creator.audit).to be_nil
    expect(creator.error).to eq(:invalid_url)
    expect(ArticleAuditWorker).not_to have_received(:run)
  end

  it 'rejects a page that does not exist' do
    allow_any_instance_of(WikiApi::ArticleContent).to receive(:latest_revision_id).and_return(nil)
    creator = described_class.new(url: 'https://en.wikipedia.org/wiki/No_such_page_xyz',
                                  requester: admin)
    expect(creator.error).to eq(:revision_not_found)
  end
end
