# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/reference_list_parser"

def parse_references(references_html)
  doc = Nokogiri::HTML(<<~HTML)
    <div class="mw-parser-output">
      <ol class="references">#{references_html}</ol>
    </div>
  HTML
  ReferenceListParser.new(doc).citations
end

def build_cite_note(id:, content:)
  %(<li id="#{id}"><span class="mw-cite-backlink"><a href="#cite_ref-1">^</a></span> ) +
    %(<span class="reference-text">#{content}</span></li>)
end

describe ReferenceListParser do
  describe '#citations' do
    it 'extracts a web citation with its URL and type' do
      cite = '<cite class="citation web cs1">Smith, Jane (2020). ' \
             '<a rel="nofollow" class="external text" href="https://example.com/article">' \
             '"An Example Article"</a>. <i>Example News</i>.</cite>'
      citations = parse_references(build_cite_note(id: 'cite_note-1', content: cite))

      expect(citations['cite_note-1']).to include(
        ref_id: 'cite_note-1',
        source_type: 'web',
        url: 'https://example.com/article',
        web_accessible: true
      )
      expect(citations['cite_note-1'][:citation_text])
        .to eq('Smith, Jane (2020). "An Example Article". Example News.')
    end

    it 'extracts a book citation, ignoring internal ISBN links' do
      cite = '<cite class="citation book cs1">Pete Myers (2012). ' \
             '<a rel="nofollow" class="external text" ' \
             'href="https://books.google.com/books?id=abc"><i>Going Home</i></a>. ' \
             '<a href="/wiki/ISBN_(identifier)" title="ISBN (identifier)">ISBN</a> ' \
             '<a href="/wiki/Special:BookSources/978-1-291-12167-4">' \
             '<bdi>978-1-291-12167-4</bdi></a>.</cite>'
      citations = parse_references(build_cite_note(id: 'cite_note-Myers-2', content: cite))

      citation = citations['cite_note-Myers-2']
      expect(citation[:source_type]).to eq('book')
      expect(citation[:urls]).to eq(['https://books.google.com/books?id=abc'])
    end

    it 'marks a citation without external links as not web-accessible' do
      cite = '<cite class="citation book cs1">Doe, John (1999). <i>Offline Book</i>. ' \
             'Some Press.</cite>'
      citations = parse_references(build_cite_note(id: 'cite_note-3', content: cite))

      expect(citations['cite_note-3']).to include(
        source_type: 'book',
        url: nil,
        urls: [],
        web_accessible: false
      )
    end

    it 'falls back to reference text with unknown type for hand-written refs' do
      content = 'See the 1987 annual report, p. 12.'
      citations = parse_references(build_cite_note(id: 'cite_note-4', content:))

      expect(citations['cite_note-4']).to include(
        citation_text: 'See the 1987 annual report, p. 12.',
        source_type: 'unknown',
        web_accessible: false
      )
    end

    it 'strips TemplateStyles and COinS noise from citation text' do
      content = '<style data-mw-deduplicate="TemplateStyles:r1">.cs1 {}</style>' \
                '<cite class="citation journal cs1">Roe, R. (2021). "A Study".</cite>' \
                '<span title="ctx_ver=Z39.88-2004" class="Z3988"></span>'
      citations = parse_references(build_cite_note(id: 'cite_note-5', content:))

      expect(citations['cite_note-5'][:citation_text]).to eq('Roe, R. (2021). "A Study".')
      expect(citations['cite_note-5'][:source_type]).to eq('journal')
    end

    it 'collects all external links from a citation' do
      cite = '<cite class="citation journal cs1">Roe, R. (2021). ' \
             '<a class="external text" href="https://example.org/paper">"A Study"</a>. ' \
             '<a class="external text" href="https://doi.org/10.1000/xyz">10.1000/xyz</a>.</cite>'
      citations = parse_references(build_cite_note(id: 'cite_note-6', content: cite))

      expect(citations['cite_note-6'][:urls])
        .to eq(['https://example.org/paper', 'https://doi.org/10.1000/xyz'])
      expect(citations['cite_note-6'][:url]).to eq('https://example.org/paper')
    end

    it 'skips list items without reference text' do
      citations = parse_references('<li id="cite_note-7"><span>no reference span</span></li>')
      expect(citations).to be_empty
    end
  end
end
