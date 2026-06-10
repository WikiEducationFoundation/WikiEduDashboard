# frozen_string_literal: true

require 'rails_helper'

def stub_article_html(html, title: 'Test Article', page_id: 123)
  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:revision_html) do |_instance, _rev_id|
    { html:, title:, page_id: }
  end
end

def claims_article_html(body, references)
  '<div class="mw-parser-output">' \
    "#{body}<ol class=\"references\">#{references}</ol></div>"
end

def claims_ref_marker(note_id, label = '1')
  "<sup id=\"cite_ref-#{note_id}\" class=\"reference\">" \
    "<a href=\"#cite_note-#{note_id}\">" \
    "<span class=\"cite-bracket\">[</span>#{label}<span class=\"cite-bracket\">]</span>" \
    '</a></sup>'
end

def claims_cite_note(note_id, url: 'https://example.com/source')
  "<li id=\"cite_note-#{note_id}\"><span class=\"reference-text\">" \
    '<cite class="citation web cs1">' \
    "<a class=\"external text\" href=\"#{url}\">\"Source #{note_id}\"</a>.</cite>" \
    '</span></li>'
end

describe ExtractClaimsAndSources do
  let(:en_wiki) { Wiki.default_wiki }

  describe '#claims' do
    it 'pairs a cited sentence with its citation details' do
      html = claims_article_html(
        "<p>The Eiffel Tower was completed in March 1889 in Paris.#{claims_ref_marker('1')}</p>",
        claims_cite_note('1')
      )
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims.length).to eq(1)
      expect(service.claims.first[:claim])
        .to eq('The Eiffel Tower was completed in March 1889 in Paris.')
      expect(service.claims.first[:citations].first).to include(
        source_type: 'web',
        url: 'https://example.com/source',
        web_accessible: true
      )
    end

    it 'attributes each reference marker to the sentence preceding it' do
      body = '<p>The bridge opened to traffic in the spring of 1937.' \
             "#{claims_ref_marker('1')} " \
             'It remained the longest suspension bridge until 1964.' \
             "#{claims_ref_marker('2', '2')}</p>"
      html = claims_article_html(body, claims_cite_note('1') + claims_cite_note('2'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims.map { |c| c[:claim] }).to eq(
        ['The bridge opened to traffic in the spring of 1937.',
         'It remained the longest suspension bridge until 1964.']
      )
      expect(service.claims.first[:citations].first[:ref_id]).to eq('cite_note-1')
      expect(service.claims.last[:citations].first[:ref_id]).to eq('cite_note-2')
    end

    it 'groups adjacent reference markers into one claim with multiple citations' do
      body = '<p>The volcano last erupted in the summer of 1883.' \
             "#{claims_ref_marker('1')}#{claims_ref_marker('2', '2')}</p>"
      html = claims_article_html(body, claims_cite_note('1') + claims_cite_note('2'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims.length).to eq(1)
      expect(service.claims.first[:citations].map { |c| c[:ref_id] })
        .to eq(%w[cite_note-1 cite_note-2])
    end

    it 'excludes the rendered marker brackets from claim text' do
      body = '<p>The museum holds over two million artifacts in its collection.' \
             "#{claims_ref_marker('1')}</p>"
      html = claims_article_html(body, claims_cite_note('1'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims.first[:claim]).not_to include('[')
    end

    it 'reads through inline links within a sentence' do
      body = '<p>The river flows through <a href="/wiki/Berlin">Berlin</a> before ' \
             "reaching the northern sea.#{claims_ref_marker('1')}</p>"
      html = claims_article_html(body, claims_cite_note('1'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims.first[:claim])
        .to eq('The river flows through Berlin before reaching the northern sea.')
    end

    it 'drops claims shorter than the minimum length' do
      body = "<p>It opened in 1990.#{claims_ref_marker('1')}</p>"
      html = claims_article_html(body, claims_cite_note('1'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims).to be_empty
    end

    it 'ignores cited sentences inside tables' do
      body = '<table><tr><td><p>The table cell mentions an important fact here.' \
             "#{claims_ref_marker('1')}</p></td></tr></table>"
      html = claims_article_html(body, claims_cite_note('1'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims).to be_empty
    end

    it 'skips markers whose reference cannot be resolved' do
      body = '<p>The observatory was built on the mountain summit in 1962.' \
             "#{claims_ref_marker('missing')}</p>"
      html = claims_article_html(body, claims_cite_note('1'))
      stub_article_html(html)
      service = described_class.new(en_wiki, mw_rev_id: 100)

      expect(service.claims).to be_empty
    end

    context 'with an only_within corpus' do
      it 'keeps only claims present in the corpus' do
        body = '<p>The harbor was dredged to a depth of twelve meters.' \
               "#{claims_ref_marker('1')} " \
               'The lighthouse was automated at the end of 1985.' \
               "#{claims_ref_marker('2', '2')}</p>"
        html = claims_article_html(body, claims_cite_note('1') + claims_cite_note('2'))
        stub_article_html(html)
        corpus = "Some other text.\n\nThe lighthouse was automated at the end of 1985."
        service = described_class.new(en_wiki, mw_rev_id: 100, only_within: corpus)

        expect(service.claims.map { |c| c[:claim] })
          .to eq(['The lighthouse was automated at the end of 1985.'])
      end
    end
  end

  describe 'fetching by title' do
    it 'resolves the latest revision of the article' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:latest_revision_id).with('Test Article').and_return(456)
      stub_article_html(claims_article_html('<p>No refs here.</p>', ''))
      service = described_class.new(en_wiki, title: 'Test Article')

      expect(service.mw_rev_id).to eq(456)
      expect(service.article_title).to eq('Test Article')
      expect(service.mw_page_id).to eq(123)
    end

    it 'produces no claims when the article does not exist' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:latest_revision_id).and_return(nil)
      service = described_class.new(en_wiki, title: 'Nonexistent Article')

      expect(service.claims).to be_empty
    end
  end
end
