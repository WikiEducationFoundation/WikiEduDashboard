# frozen_string_literal: true

require 'rails_helper'

describe FindSourceVerificationExamples do
  let(:course) { create(:course) }
  let(:wiki) { Wiki.default_wiki }
  let(:student) { create(:user, username: 'StudentUser') }
  let(:article) do
    create(:article, title: 'Test_Article', mw_page_id: 42, namespace: 0, wiki_id: wiki.id)
  end

  def example_article_html
    body = '<p>The lighthouse was automated at the end of 1985.' \
           '<sup id="cite_ref-1" class="reference"><a href="#cite_note-1">[1]</a></sup> ' \
           'The harbor was dredged to a depth of twelve meters.' \
           '<sup id="cite_ref-2" class="reference"><a href="#cite_note-2">[2]</a></sup></p>'
    references = '<li id="cite_note-1"><span class="reference-text">' \
                 '<cite class="citation web cs1"><a class="external text" ' \
                 'href="https://example.com/lighthouse">"Lighthouse"</a>.</cite></span></li>' \
                 '<li id="cite_note-2"><span class="reference-text">' \
                 '<cite class="citation news cs1"><a class="external text" ' \
                 'href="https://example.com/harbor">"Harbor"</a>.</cite></span></li>'
    "<div class=\"mw-parser-output\">#{body}<ol class=\"references\">#{references}</ol></div>"
  end

  def stub_student_revision_history(revisions)
    allow_any_instance_of(WikiApi::ArticleContent)
      .to receive(:revision_history).and_return(revisions)
  end

  def stub_live_article(html:, title: 'Test Article', page_id: 42, rev_id: 500)
    allow_any_instance_of(WikiApi::ArticleContent)
      .to receive(:latest_revision_id).and_return(rev_id)
    allow_any_instance_of(WikiApi::ArticleContent)
      .to receive(:revision_html).and_return({ html:, title:, page_id: })
  end

  def stub_student_added_text(text)
    plaintext = instance_double(GetRevisionPlaintext, plain_text: text)
    allow(GetRevisionPlaintext).to receive(:new).and_return(plaintext)
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    create(:articles_course, course:, article:, references_count: 3)
  end

  describe '#examples' do
    it 'returns claims from student-added content with article details merged in' do
      stub_student_revision_history([{ 'revid' => 300, 'user' => 'StudentUser' },
                                     { 'revid' => 299, 'user' => 'RandoEditor' }])
      stub_student_added_text('The lighthouse was automated at the end of 1985.')
      stub_live_article(html: example_article_html)

      examples = described_class.new(course).examples

      expect(examples.length).to eq(1)
      expect(examples.first).to include(
        claim: 'The lighthouse was automated at the end of 1985.',
        article_title: 'Test Article',
        article_id: article.id,
        mw_page_id: 42,
        mw_rev_id: 500
      )
      expect(examples.first[:citations].first[:url]).to eq('https://example.com/lighthouse')
      expect(GetRevisionPlaintext).to have_received(:new).with(300, wiki)
      expect(GetRevisionPlaintext).not_to have_received(:new).with(299, wiki)
    end

    it 'skips articles with no student revisions' do
      stub_student_revision_history([{ 'revid' => 299, 'user' => 'RandoEditor' }])
      allow(GetRevisionPlaintext).to receive(:new)

      examples = described_class.new(course).examples

      expect(examples).to be_empty
      expect(GetRevisionPlaintext).not_to have_received(:new)
    end

    it 'skips articles whose student-added text is blank' do
      stub_student_revision_history([{ 'revid' => 300, 'user' => 'StudentUser' }])
      stub_student_added_text(nil)
      html_fetched = false
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_html) { html_fetched = true }

      examples = described_class.new(course).examples

      expect(examples).to be_empty
      expect(html_fetched).to eq(false)
    end

    it 'stops once max_examples is reached' do
      stub_student_revision_history([{ 'revid' => 300, 'user' => 'StudentUser' }])
      stub_student_added_text(
        'The lighthouse was automated at the end of 1985. ' \
        'The harbor was dredged to a depth of twelve meters.'
      )
      stub_live_article(html: example_article_html)

      examples = described_class.new(course, max_examples: 1).examples

      expect(examples.length).to eq(1)
    end

    it 'does not query articles without references' do
      unreferenced_article = create(:article, title: 'No_Refs', mw_page_id: 43,
                                              namespace: 0, wiki_id: wiki.id)
      create(:articles_course, course:, article: unreferenced_article, references_count: 0)
      history_calls = []
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_history) do |_instance, page_id, **_opts|
        history_calls << page_id
        []
      end

      described_class.new(course)

      expect(history_calls).to eq([42])
    end

    it 'skips an article that raises and continues with the rest' do
      failing_article = create(:article, title: 'Failing_Article', mw_page_id: 41,
                                         namespace: 0, wiki_id: wiki.id)
      create(:articles_course, course:, article: failing_article, references_count: 9)
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_history) do |_instance, page_id, **_opts|
        raise StandardError, 'API trouble' if page_id == 41
        [{ 'revid' => 300, 'user' => 'StudentUser' }]
      end
      stub_student_added_text('The lighthouse was automated at the end of 1985.')
      stub_live_article(html: example_article_html)
      allow(Sentry).to receive(:capture_exception)

      examples = described_class.new(course).examples

      expect(examples.length).to eq(1)
      expect(examples.first[:article_id]).to eq(article.id)
      expect(Sentry).to have_received(:capture_exception)
    end
  end
end
