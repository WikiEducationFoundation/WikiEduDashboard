# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/wiki_link_resolver"

describe WikiLinkResolver do
  describe '.resolve' do
    it 'resolves an interwiki wikilink with a bare project prefix to a real url' do
      input = '[[wikipedia:Wikipedia:Notability#General_notability_guideline' \
              '|General Notabilty Guidelines]]'
      output = described_class.resolve(input)
      expect(output).to eq(
        '[https://en.wikipedia.org/wiki/Wikipedia:Notability#General_notability_guideline ' \
        'General Notabilty Guidelines]'
      )
    end

    it 'resolves an interwiki wikilink with no pipe using the target as the label' do
      input = '[[wikipedia:Wikipedia:Red_link|redlinks]]'
      output = described_class.resolve(input)
      expect(output).to eq('[https://en.wikipedia.org/wiki/Wikipedia:Red_link redlinks]')
    end

    it 'resolves a short "w:" prefix with an explicit language sub-prefix' do
      input = '[[w:eu:Wikipedia:Genero_oreka|Generoko zuloa]]'
      output = described_class.resolve(input)
      expect(output).to eq('[https://eu.wikipedia.org/wiki/Wikipedia:Genero_oreka Generoko zuloa]')
    end

    it 'resolves a bare page title to a meta.wikimedia.org link' do
      input = '[[Gender gap]]'
      output = described_class.resolve(input)
      expect(output).to eq('[https://meta.wikimedia.org/wiki/Gender_gap Gender gap]')
    end

    it 'leaves a Category wikilink (no leading colon) untouched' do
      input = '[[Category:Editathon training slides]]'
      expect(described_class.resolve(input)).to eq(input)
    end

    it 'leaves a leading-colon Category link untouched, since it is not a recognized project' do
      input = '[[:Category:Foo|Text]]'
      expect(described_class.resolve(input)).to eq(input)
    end

    it 'leaves a File embed untouched' do
      input = '[[File:Foo.jpg|thumb|caption]]'
      expect(described_class.resolve(input)).to eq(input)
    end

    it 'leaves a same-page anchor link untouched' do
      input = '[[#Section]]'
      expect(described_class.resolve(input)).to eq(input)
    end

    it 'leaves an unrecognized namespace untouched' do
      input = '[[Talk:Some Page|discussion]]'
      expect(described_class.resolve(input)).to eq(input)
    end

    it 'leaves plain external links untouched' do
      input = '[https://meta.wikimedia.org/wiki/Gender_gap gender gap]'
      expect(described_class.resolve(input)).to eq(input)
    end
  end
end
