# frozen_string_literal: true

require 'rails_helper'

def stub_citation_revision_html(html)
  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:revision_html) do |_instance, _rev_id|
    { html: html, title: 'Test Article', page_id: 123 }
  end
end

def stub_citation_diff_api(diff_html, parsed_html: nil)
  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:revision_diff) do |_instance, _from_rev, _to_rev|
    { diff_html: diff_html, title: 'Test', page_id: 1 }
  end

  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:parse_wikitext) do |_instance, text|
    parsed_html || "<div>#{text}</div>"
  end
end

def citation_diff_row(added_text)
  '<table><tr>' \
    '<td class="diff-empty">&#160;</td>' \
    '<td class="diff-addedline">' \
    "<div>#{added_text}</div></td></tr></table>"
end

describe GetRevisionHtmlWithCitations do
  let(:en_wiki) { Wiki.default_wiki }

  context 'in full-revision mode' do
    it 'returns the revision HTML with citation markup intact' do
      html = <<~HTML
        <p>Some claim.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
        <ol class="references">
          <li id="cite_note-1"><cite>Author. Title.</cite></li>
        </ol>
      HTML
      stub_citation_revision_html(html)
      service = described_class.new(12345, en_wiki, diff_mode: false)
      expect(service.html).to include('sup class="reference"')
      expect(service.html).to include('<cite>')
      expect(service.article_title).to eq('Test Article')
    end
  end

  context 'in diff mode' do
    it 'parses only the changed wikitext, with a references list appended' do
      added = 'New sentence.<ref>{{cite web |url=http://example.com |title=Source}}</ref>'
      parsed_wikitext = nil
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_diff)
        .and_return({ diff_html: citation_diff_row(added), title: 'Test', page_id: 1 })
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:parse_wikitext) do |_instance, text|
        parsed_wikitext = text
        '<p>parsed</p>'
      end

      described_class.new(100, en_wiki, from_rev: 99)
      expect(parsed_wikitext).to include('New sentence.')
      expect(parsed_wikitext).to end_with("\n<references />")
    end

    it 'returns the parser output as html' do
      stub_citation_diff_api(citation_diff_row('New content.'),
                             parsed_html: '<p>New content.</p>')
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.html).to eq('<p>New content.</p>')
      expect(service.article_title).to eq('Test')
    end

    it 'fetches the parent revision when from_rev is not given' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:parent_revision_id).and_return(99)
      stub_citation_diff_api(citation_diff_row('New content.'))
      service = described_class.new(100, en_wiki)
      expect(service.html).to include('New content.')
    end

    it 'falls back to full revision HTML for the first revision of a page' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:parent_revision_id).and_return(0)
      stub_citation_revision_html('<p>First revision.</p>')
      service = described_class.new(100, en_wiki)
      expect(service.html).to eq('<p>First revision.</p>')
    end

    it 'returns nil html when the parent revision is unavailable' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:parent_revision_id).and_return(nil)
      service = described_class.new(100, en_wiki)
      expect(service.html).to be_nil
    end

    it 'returns nil html when the diff is unavailable' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_diff).and_return(nil)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.html).to be_nil
    end

    it 'returns nil html when the diff contains no added text' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_diff)
        .and_return({ diff_html: '<table></table>', title: 'Test', page_id: 1 })
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.html).to be_nil
    end
  end
end
