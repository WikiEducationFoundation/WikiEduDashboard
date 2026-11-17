# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/rendered_article"

describe ArticleAuditing::RenderedArticle do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:html) { '<p>Acme is great.</p>' }
  let(:context) do
    instance_double(ArticleAuditing::Context, wiki:, mw_rev_id: 123, html:,
                                              wikitext: "'''Acme''' is great.")
  end
  let(:article) { { html: '<p>Acme is great.</p>', wikitext: "'''Acme''' is great." } }

  before do
    allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::MemoryStore.new)
    allow(ArticleAuditing::Context).to receive(:new).with(wiki:, mw_rev_id: 123)
                                                    .and_return(context)
  end

  it 'fetches the revision once and then serves it from the cache' do
    2.times { expect(described_class.fetch(wiki, 123)).to eq(article) }
    expect(ArticleAuditing::Context).to have_received(:new).once
  end

  it 'serves an article stored while the audit ran without fetching it' do
    described_class.store(context)
    expect(described_class.fetch(wiki, 123)).to eq(article)
    expect(ArticleAuditing::Context).not_to have_received(:new)
  end

  context 'when the revision cannot be fetched' do
    let(:html) { '' }

    it 'returns nil and tries again next time' do
      2.times { expect(described_class.fetch(wiki, 123)).to be_nil }
      expect(ArticleAuditing::Context).to have_received(:new).twice
    end
  end
end
