# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/context"

describe ArticleAuditing::Context do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:context) { described_class.new(wiki:, mw_rev_id: 99) }
  let(:namespace) { 2 }
  let(:parent_id) { 5 }
  let(:wiki_context) do
    instance_double(ArticleAuditing::WikiContext, target_title: 'Marie Curie',
                                                  target_exists?: target_exists)
  end
  let(:target_exists) { true }

  before do
    allow(context).to receive_messages(
      revision_info: { title: 'User:Ex/Marie Curie', namespace:, page_id: 1, parent_id: },
      wikitext: "'''Marie''' & <b>",
      wiki_context:
    )
  end

  describe '#new_article?' do
    it 'is false for a draft of an existing article' do
      expect(context.new_article?).to be(false)
    end

    context 'when the draft’s target does not exist' do
      let(:target_exists) { false }

      it 'is true' do
        expect(context.new_article?).to be(true)
      end
    end

    context 'when the page is in mainspace' do
      let(:namespace) { 0 }

      it 'depends on whether this is the page’s first revision' do
        expect(context.new_article?).to be(false)
        allow(context).to receive(:revision_info)
          .and_return(title: 'Marie Curie', namespace: 0, page_id: 1, parent_id: 0)
        expect(context.new_article?).to be(true)
      end
    end
  end

  describe '#llm_system_blocks' do
    it 'puts the article, with its target, in a cached block after the instructions' do
      instructions, article = context.llm_system_blocks
      expect(instructions[:cache]).to be(false)
      expect(article[:cache]).to be(true)
      expect(article[:text]).to include('title="User:Ex/Marie Curie"', 'target_title="Marie Curie"',
                                        'target_exists="true"', "'''Marie''' & <b>")
    end
  end
end
