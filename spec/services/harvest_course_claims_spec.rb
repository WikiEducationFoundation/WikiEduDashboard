# frozen_string_literal: true

require 'rails_helper'

describe HarvestCourseClaims do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) { create(:course, subject: 'Ecology') }
  let(:article) { create(:article, wiki:, title: 'Otter', namespace: Article::Namespaces::MAINSPACE) }

  let(:html) do
    <<~HTML
      <p>Otters use tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Otters</a></cite></span></li></ol>
    HTML
  end

  before do
    create(:articles_course, course:, article:)
    article_content = instance_double(WikiApi::ArticleContent, latest_revision_id: 999)
    allow(WikiApi::ArticleContent).to receive(:new).and_return(article_content)
    html_service = instance_double(GetRevisionHtmlWithCitations, html:)
    allow(GetRevisionHtmlWithCitations).to receive(:new).and_return(html_service)
  end

  it "stores the course articles' cited claims, tagged with the course subject" do
    described_class.new(course)
    claim = VerificationClaim.find_by(mw_rev_id: 999)
    expect([claim.sentence, claim.subject, claim.source_course_id, claim.article_id])
      .to eq(['Otters use tools.', 'Ecology', course.id, article.id])
  end

  it 'skips sandbox/userspace articles, harvesting only mainspace' do
    sandbox = create(:article, wiki:, title: 'User:Z/Otter',
                               namespace: Article::Namespaces::USER)
    create(:articles_course, course:, article: sandbox)
    described_class.new(course)
    expect(VerificationClaim.pluck(:article_id).uniq).to eq([article.id])
  end

  it 'logs and skips an article whose harvest raises, without aborting' do
    allow(GetRevisionHtmlWithCitations).to receive(:new).and_raise(StandardError, 'boom')
    expect { described_class.new(course) }.not_to raise_error
    expect(VerificationClaim.count).to eq(0)
  end
end
