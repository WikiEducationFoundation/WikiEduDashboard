# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

describe TakeVerificationClaim do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:article) do
    create(:article, wiki:, title: 'Otter', namespace: Article::Namespaces::MAINSPACE)
  end

  let(:html) do
    <<~HTML
      <p>Otters use tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Otters</a></cite></span></li></ol>
    HTML
  end

  before do
    article_content = instance_double(WikiApi::ArticleContent, latest_revision_id: 321)
    allow(WikiApi::ArticleContent).to receive(:new).and_return(article_content)
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html:))
  end

  def take(sentence:, ref_id:)
    described_class.new(user:, course:, article:, sentence:, ref_id:)
  end

  it 'persists the chosen claim and records it as the assignment' do
    result = take(sentence: 'Otters use tools.', ref_id: 'cite_note-1')
    expect(result.assignment.verification_claim.sentence).to eq('Otters use tools.')
    expect(result.assignment.verification_claim.article_id).to eq(article.id)
    expect(result.assignment.user).to eq(user)
  end

  it 'returns no assignment when the chosen claim is not found in the article' do
    expect(take(sentence: 'Not in the article.', ref_id: 'cite_note-9').assignment).to be_nil
  end

  it 'does not duplicate the claim or assignment on a repeat take' do
    take(sentence: 'Otters use tools.', ref_id: 'cite_note-1')
    expect { take(sentence: 'Otters use tools.', ref_id: 'cite_note-1') }
      .not_to change(VerificationClaim, :count)
    expect(VerificationClaimAssignment.where(user:, course:).count).to eq(1)
  end
end
