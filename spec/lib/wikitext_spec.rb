# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wikitext"

describe Wikitext do
  let(:subject) { described_class }

  describe '.markdown_to_mediawiki' do
    it 'returns a wikitext formatted version of the markdown input' do
      title = subject.markdown_to_mediawiki('# Title #')
      text = subject.markdown_to_mediawiki('This is some plain text')
      response = title + text
      expect(response).to match("= Title =\nThis is some plain text\n")
    end

    it 'renders a list without a blank line preceding it, a la GitHub-style markdown' do
      list = <<~MARKDOWN
        My list:
        * first
        * second
      MARKDOWN
      expected = <<~MEDIAWIKI
        My list:

        * first
      MEDIAWIKI
      output = subject.markdown_to_mediawiki(list)
      expect(output).to include(expected.chomp)
    end

    it 'handles raw links with unicode characters correctly' do
      # Pandoc behaves differently for raw links that include unicode characters,
      # converting them to wikilinks when similar input without the unicode would
      # be left as a raw link.
      # Here, we're making sure they get converted back to a format that works on-wiki.
      input = 'Více na: https://cs.wikipedia.org/wiki/Wikipedie:WikiMěsto_Kopřivnice'
      expected = '[https://cs.wikipedia.org/wiki/Wikipedie:WikiMěsto_Kopřivnice https://cs.wikipedia.org/wiki/Wikipedie:WikiMěsto_Kopřivnice]'
      # Some versions of Pandoc don't have this bug and treat it as raw text, so that's
      # an acceptable alternative
      alternative_expected = 'Více na: https://cs.wikipedia.org/wiki/Wikipedie:WikiMěsto_Kopřivnice'
      output = subject.markdown_to_mediawiki(input)
      expect(output).to include(expected).or(include(alternative_expected))
    end
  end

  describe '.replace_code_with_nowiki' do
    it 'converts code formatting syntax from html to wikitext' do
      code_snippet = '<code></code>'
      response = subject.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('<nowiki></nowiki>')
    end

    it 'does not return nil if there are no code snippet' do
      code_snippet = 'no code snippet here'
      response = subject.replace_code_with_nowiki(code_snippet)
      expect(response).to eq('no code snippet here')
    end
  end

  describe '.replace_at_sign_with_template' do
    it 'reformats email addresses' do
      code_snippet = 'My email is email@example.com.'
      response = subject.replace_at_sign_with_template(code_snippet)
      expect(response).to eq('My email is email{{@}}example.com.')
    end
  end

  describe '.substitute_bad_links' do
    it 'finds links and munge them into readable non-urls' do
      code_snippet = 'My bad links are bit.ly/foo and http://ur1.ca/bar'
      bad_links = ['bit.ly/foo', 'ur1.ca/bar']
      response = subject.substitute_bad_links(code_snippet, bad_links)
      expect(response).to include 'bit(.)ly/foo'
      expect(response).to include 'ur1(.)ca/bar'
      expect(response).not_to include 'bit.ly/foo'
      expect(response).not_to include 'ur1.ca/bar'
    end
  end

  describe '.assignments_to_wikilinks' do
    let(:en_wiki) { Wiki.find_by(language: 'en', project: 'wikipedia') }
    let(:es_wiki) { create(:wiki, language: 'es', project: 'wikipedia') }
    let(:es_wiktionary) { create(:wiki, language: 'es', project: 'wiktionary') }
    let(:en_wikinews) { create(:wiki, language: 'en', project: 'wikinews') }
    let(:en_wikibooks) { create(:wiki, language: 'en', project: 'wikibooks') }
    let(:pl_wikiquote) { create(:wiki, language: 'pl', project: 'wikiquote') }
    let(:es_wikisource) { create(:wiki, language: 'es', project: 'wikisource') }
    let(:wikidata) { create(:wiki, project: 'wikidata') }
    let(:de_wikiversity) { create(:wiki, language: 'de', project: 'wikiversity') }
    let(:en_wikivoyage) { create(:wiki, language: 'en', project: 'wikivoyage') }
    let(:commons) { create(:wiki, language: 'commons', project: 'wikimedia') }
    # Disabled due to Invalid Project:
    # (`raise InvalidWikiError unless PROJECTS.include?(project)`) in app/models/wiki.rb
    # let(:metawikipedia) { create(:wiki, language: 'en', project: 'metawikipedia') }
    # let(:meta) { create(:wiki, language: 'en', project: 'meta') }
    # let(:wikispecies) { create(:wiki, project: 'wikispecies') }

    let(:assignments) do
      [
        create(:assignment, article_title: 'Selfie'),
        create(:assignment, article_title: 'Category:Photography'),
        create(:assignment, article_title: 'Bishnu Priya'),
        create(:assignment, article_title: 'Blanca de Beaulieu', wiki: es_wiki),
        create(:assignment, article_title: 'agrazarías', wiki: es_wiktionary),
        create(
          :assignment,
          article_title: 'Manned Soyuz space mission aborts during launch',
          wiki: en_wikinews
        ),
        create(:assignment, article_title: 'Q60', wiki: wikidata),
        create(:assignment, article_title: 'Mastering the Kitchen', wiki: en_wikibooks),
        create(:assignment, article_title: 'Theodore Roosevelt', wiki: pl_wikiquote),
        create(:assignment, article_title: 'Novelas y fantasías', wiki: es_wikisource),
        create(:assignment, article_title: 'Mathematik', wiki: de_wikiversity),
        create(:assignment, article_title: 'Previous Featured travel topics', wiki: en_wikivoyage),
        create(:assignment,
               article_title: 'File:Black-headed lapwing (Vanellus tectus tectus).jpg',
               wiki: commons)
        # Disabled due to Invalid Project:
        # (`raise InvalidWikiError unless PROJECTS.include?(project)`) in app/models/wiki.rb
        # create(:assignment, article_title: 'Hardware donation program', wiki: meta)
        # create(:assignment, article_title: 'Wiki4MediaFreedom contest - II edition', wiki: metawik
        # ipedia),
        # create(:assignment, article_title: 'Sitta europaea caesia', wiki: wikispecies),
      ]
    end

    before { stub_wiki_validation }

    it 'converts a set of assignments into wikilink format' do
      output = subject.assignments_to_wikilinks(assignments, en_wiki)
      expect(output).to include('[[Selfie]], ')
      expect(output).to include('[[:Category:Photography]]')
      expect(output).to include('[[Bishnu Priya]]')
      expect(output).to include('[[:es:Blanca de Beaulieu]]')
      expect(output).to include('[[:wikt:es:agrazarías]]')
      expect(output).to include('[[:wikidata:Q60]]')
      expect(output).to include('[[:n:en:Manned Soyuz space mission aborts during launch]]')
      expect(output).to include('[[:b:en:Mastering the Kitchen]]')
      expect(output).to include('[[:q:pl:Theodore Roosevelt]]')
      expect(output).to include('[[:s:es:Novelas y fantasías')
      expect(output).to include('[[:v:de:Mathematik]]')
      expect(output).to include('[[:voy:en:Previous Featured travel topics]]')
      expect(output).to include('[[:c:File:Black-headed lapwing (Vanellus tectus tectus).jpg]]')
      # expect(output).to include('[[:m:en:Wiki4MediaFreedom contest - II edition]]')
      # expect(output).to include('[[:n:en:Hardware donation program]]')
      # expect(output).to include('[[:species:Sitta europaea caesia]]')
    end
  end
end
