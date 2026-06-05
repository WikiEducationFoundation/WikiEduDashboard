# frozen_string_literal: true

require 'rails_helper'

def stub_diff_api(diff_html)
  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:revision_diff) do |_instance, _from_rev, _to_rev|
    {
      diff_html: diff_html,
      title: 'Test',
      page_id: 1
    }
  end

  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:parse_wikitext) do |_instance, text|
    "<p>#{text}</p>"
  end
end

def build_diff_row(deleted_text, added_text)
  deleted = '<td class="diff-deletedline">' \
            "<div>#{deleted_text}</div></td>"
  added = '<td class="diff-addedline">' \
          "<div>#{added_text}</div></td>"
  "<table><tr>#{deleted}#{added}</tr></table>"
end

def build_new_row(added_text)
  '<table><tr>' \
    '<td class="diff-empty">&#160;</td>' \
    '<td class="diff-addedline">' \
    "<div>#{added_text}</div></td></tr></table>"
end

def stub_revision_html(html)
  allow_any_instance_of(WikiApi::ArticleContent)
    .to receive(:revision_html) do |_instance, _rev_id|
    {
      html: html,
      title: 'Test Article',
      page_id: 123
    }
  end
end

describe GetRevisionPlaintext do
  let(:en_wiki) { Wiki.default_wiki }

  describe '#plain_text' do
    it 'excludes figure-based images and captions' do
      stub_revision_html(<<~HTML)
        <p>Start text.</p>
        <figure typeof="mw:File/Thumb">
          <a href="/wiki/File:Example.jpg"><img src="example.jpg" /></a>
          <figcaption>Example caption</figcaption>
        </figure>
        <p>End text.</p>
      HTML
      service = described_class.new(12345, en_wiki, diff_mode: false)
      expect(service.plain_text).to include('Start text.')
      expect(service.plain_text).to include('End text.')
      expect(service.plain_text).not_to include('Example caption')
    end

    it 'excludes inline images' do
      stub_revision_html(<<~HTML)
        <p>Text before <a href="/wiki/File:Icon.png" class="image"><img src="icon.png" /></a> text after.</p>
      HTML
      service = described_class.new(12345, en_wiki, diff_mode: false)
      expect(service.plain_text).to include('Text before')
      expect(service.plain_text).to include('text after')
    end

    it 'preserves normal prose' do
      stub_revision_html('<p>Just some normal text.</p>')
      service = described_class.new(12345, en_wiki, diff_mode: false)
      expect(service.plain_text).to eq('Just some normal text.')
    end
  end

  context 'when new sentences are added at end of paragraph' do
    it 'excludes the pre-existing content' do
      old = 'Third places are important for civil society.'
      ins = 'Scholars have noted that online forums ' \
            'can function as third places.'
      diff_html = build_diff_row(
        old,
        "#{old} <ins class=\"diffchange\">#{ins}</ins>"
      )
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('Scholars have noted')
      expect(service.plain_text).not_to include(
        'Third places are important'
      )
    end
  end

  context 'when new sentences are added at beginning' do
    it 'excludes the pre-existing content' do
      old = 'The coffee shop has been popular since the 1990s.'
      ins = 'Originally founded as a bookstore in 1988.'
      diff_html = build_diff_row(
        old,
        "<ins class=\"diffchange\">#{ins}</ins> #{old}"
      )
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('Originally founded')
      expect(service.plain_text).not_to include(
        'The coffee shop has been popular'
      )
    end
  end

  context 'when the edit is a rewrite' do
    it 'keeps the full rewritten content' do
      old_text = 'The <del class="diffchange">' \
                 'building was constructed in 1990</del>.'
      new_text = 'The <ins class="diffchange">' \
                 'structure was originally built in 1985</ins>.'
      diff_html = build_diff_row(old_text, new_text)
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include(
        'structure was originally built'
      )
      expect(service.plain_text).to include('The')
    end
  end

  context 'when an entirely new paragraph is added' do
    it 'keeps the full new content' do
      new_text = 'This is an entirely new paragraph ' \
                 'added by the student.'
      diff_html = build_new_row(new_text)
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include(
        'This is an entirely new paragraph'
      )
    end
  end

  context 'when multiple rows have different changes' do
    it 'handles each row appropriately' do
      old = 'The park was established in 1950.'
      ins = 'It covers 500 acres.'
      row1_del = '<td class="diff-deletedline">' \
                 "<div>#{old}</div></td>"
      row1_add = '<td class="diff-addedline"><div>' \
                 "#{old} <ins class=\"diffchange\">" \
                 "#{ins}</ins></div></td>"
      row2 = '<tr><td class="diff-empty">&#160;</td>' \
             '<td class="diff-addedline"><div>' \
             'The park is home to over 200 species ' \
             'of birds.</div></td></tr>'
      diff_html = "<table><tr>#{row1_del}#{row1_add}</tr>" \
                  "#{row2}</table>"
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('It covers 500 acres')
      expect(service.plain_text).not_to include(
        'The park was established in 1950'
      )
      expect(service.plain_text).to include(
        'The park is home to over 200 species'
      )
    end
  end

  context 'when a single word is changed' do
    it 'keeps full content since it is a modification' do
      old = 'The project was ' \
            '<del class="diffchange">started</del>' \
            ' in 2010 by volunteers.'
      new_text = 'The project was ' \
                 '<ins class="diffchange">launched</ins>' \
                 ' in 2010 by volunteers.'
      diff_html = build_diff_row(old, new_text)
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('The project was')
      expect(service.plain_text).to include('launched')
    end
  end

  context 'when new sentences include references' do
    it 'extracts only the new content' do
      old = 'Urbanization drives economic growth.'
      ins = 'Studies suggest urban sprawl ' \
            'increases emissions.'
      diff_html = build_diff_row(
        old,
        "#{old} <ins class=\"diffchange\">#{ins}</ins>"
      )
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('Studies suggest')
      expect(service.plain_text).not_to include(
        'Urbanization drives'
      )
    end
  end

  context 'when the deleted line is empty' do
    it 'keeps all added content' do
      diff_html = build_diff_row(
        '',
        'Brand new content that did not exist before.'
      )
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include('Brand new content')
    end
  end

  context 'when there are no diffchange markers' do
    it 'keeps the full added content' do
      diff_html = build_diff_row(
        'Old version of paragraph.',
        'Completely new version of paragraph.'
      )
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include(
        'Completely new version'
      )
    end
  end

  # VCR-based test using real Wikipedia diff
  # Third_place example from issue #6706
  context 'with a real Wikipedia diff (Third_place)' do
    it 'excludes pre-existing content from plain_text' do
      VCR.use_cassette 'cached/get_revision_plaintext/third_place' do
        service = described_class.new(
          1340536495, en_wiki
        )
        expect(service.plain_text).to include(
          'Scholars have noted'
        )
        expect(service.plain_text).not_to include(
          'In sociology, the third place'
        )
      end
    end
  end

  context 'when revision content is suppressed between scheduling and fetch' do
    it 'returns nil plain_text without raising' do
      allow_any_instance_of(WikiApi::ArticleContent)
        .to receive(:revision_diff).and_return(nil)
      service = described_class.new(1351319293, en_wiki, from_rev: 1351319292)
      expect(service.plain_text).to be_nil
    end
  end

  context 'when a phrase is added mid-sentence' do
    it 'keeps the full sentence to avoid fragments' do
      old = 'The building was constructed in 1990.'
      new_text = 'The building was constructed in 1990' \
                 '<ins class="diffchange"> and later ' \
                 'renovated in 2005</ins>.'
      diff_html = build_diff_row(old, new_text)
      stub_diff_api(diff_html)
      service = described_class.new(100, en_wiki, from_rev: 99)
      expect(service.plain_text).to include(
        'The building was constructed'
      )
      expect(service.plain_text).to include(
        'renovated in 2005'
      )
    end
  end
end
