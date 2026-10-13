# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/article_title_input_parser"

describe ArticleTitleInputParser do
  def parse(input)
    described_class.new(input)
  end

  describe 'titles' do
    it 'keeps a plain title' do
      expect(parse('Marie Curie').title).to eq('Marie Curie')
    end

    it 'strips whitespace and replaces underscores' do
      expect(parse("  Marie_Curie \n").title).to eq('Marie Curie')
    end

    it 'keeps a title with a slash or a dot' do
      expect(parse('AC/DC').title).to eq('AC/DC')
      expect(parse('Booking.com').title).to eq('Booking.com')
    end

    it 'keeps a literal plus' do
      expect(parse('C++').title).to eq('C++')
    end

    it 'keeps a percent sign that is not an escape' do
      expect(parse('100% Pure').title).to eq('100% Pure')
    end

    it 'decodes a percent-encoded title' do
      expect(parse('Jalape%C3%B1o').title).to eq('Jalapeño')
    end

    it 'leaves malformed percent-encoding alone' do
      expect(parse('Jalape%C3o').title).to eq('Jalape%C3o')
    end

    it 'unwraps a wikilink' do
      expect(parse('[[Marie Curie]]').title).to eq('Marie Curie')
    end

    it 'unwraps a piped wikilink' do
      expect(parse('[[Marie Curie|Curie]]').title).to eq('Marie Curie')
    end

    it 'returns nothing for blank input' do
      parser = parse('   ')
      expect([parser.title, parser.revision_id, parser.page_id]).to all(be_nil)
    end

    it 'returns nothing for nil' do
      expect(parse(nil).title).to be_nil
    end
  end

  describe '/wiki/ URLs' do
    it 'parses an article URL' do
      expect(parse('https://en.wikipedia.org/wiki/Marie_Curie').title).to eq('Marie Curie')
    end

    it 'parses a URL without a scheme' do
      expect(parse('en.wikipedia.org/wiki/Marie_Curie').title).to eq('Marie Curie')
    end

    it 'parses an http URL' do
      expect(parse('http://en.wikipedia.org/wiki/Marie_Curie').title).to eq('Marie Curie')
    end

    it 'parses a mobile URL' do
      expect(parse('https://en.m.wikipedia.org/wiki/Marie_Curie').title).to eq('Marie Curie')
    end

    it 'drops a section fragment' do
      expect(parse('https://en.wikipedia.org/wiki/Marie_Curie#Early_life').title)
        .to eq('Marie Curie')
    end

    it 'drops the mobile editor fragment' do
      expect(parse('https://en.m.wikipedia.org/wiki/Marie_Curie#/editor/0').title)
        .to eq('Marie Curie')
    end

    it 'drops a query string' do
      expect(parse('https://en.wikipedia.org/wiki/Marie_Curie?veaction=edit').title)
        .to eq('Marie Curie')
    end

    it 'decodes percent-encoding' do
      expect(parse('https://es.wikipedia.org/wiki/Jalape%C3%B1o').title).to eq('Jalapeño')
      expect(parse('https://en.wikipedia.org/wiki/Selfie_%28photography%29').title)
        .to eq('Selfie (photography)')
    end

    it 'decodes an escaped question mark in the title' do
      expect(parse('https://en.wikipedia.org/wiki/What%27s_the_411%3F').title)
        .to eq("What's the 411?")
    end

    it 'keeps a literal plus in the path' do
      expect(parse('https://en.wikipedia.org/wiki/C++').title).to eq('C++')
      expect(parse('https://en.wikipedia.org/wiki/C%2B%2B').title).to eq('C++')
    end

    it 'parses a URL with unencoded non-ASCII characters' do
      expect(parse('https://es.wikipedia.org/wiki/Jalapeño').title).to eq('Jalapeño')
    end
  end

  describe '/w/index.php URLs' do
    it 'parses a source edit URL' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Marie_Curie&action=edit')
      expect(parser.title).to eq('Marie Curie')
    end

    it 'parses a section edit URL' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Marie_Curie&action=edit&section=2')
      expect(parser.title).to eq('Marie Curie')
    end

    it 'parses a history URL' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Marie_Curie&action=history')
      expect(parser.title).to eq('Marie Curie')
    end

    it 'parses a URL with only a title' do
      expect(parse('https://en.wikipedia.org/w/index.php?title=Marie_Curie').title)
        .to eq('Marie Curie')
    end

    it 'parses a URL where the title is not the first parameter' do
      parser = parse('https://en.wikipedia.org/w/index.php?action=edit&title=Marie_Curie')
      expect(parser.title).to eq('Marie Curie')
    end

    it 'prefers the title to a revision id' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Marie_Curie&diff=prev&oldid=123')
      expect(parser.title).to eq('Marie Curie')
      expect(parser.revision_id).to be_nil
    end

    it 'parses a mobile redlink URL' do
      parser = parse('https://en.m.wikipedia.org/w/index.php?title=Red_link&action=edit&redlink=1')
      expect(parser.title).to eq('Red link')
    end

    it 'decodes a title with parentheses and non-ASCII characters' do
      url = 'https://en.wikipedia.org/w/index.php?title=Smedsb%C3%B6le_Radio_Mast_%28Finland%29&oldid=1'
      expect(parse(url).title).to eq('Smedsböle Radio Mast (Finland)')
    end

    it 'reads a plus in the query as a space' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Marie+Curie&action=edit')
      expect(parser.title).to eq('Marie Curie')
    end

    it 'reads an escaped plus in the query as a plus' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=C%2B%2B&action=edit')
      expect(parser.title).to eq('C++')
    end

    it 'reads an escaped ampersand in the title' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=AT%26T&action=edit')
      expect(parser.title).to eq('AT&T')
    end
  end

  describe 'links with ids instead of a title' do
    it 'parses a diff' do
      parser = parse('https://en.wikipedia.org/w/index.php?diff=1315039613')
      expect(parser.title).to be_nil
      expect(parser.revision_id).to eq(1315039613)
    end

    it 'parses a diff range by its newer revision' do
      parser = parse('https://en.wikipedia.org/w/index.php?diff=1178859026&oldid=711811679')
      expect(parser.revision_id).to eq(1178859026)
    end

    it 'parses a diff against the previous revision' do
      parser = parse('https://en.wikipedia.org/w/index.php?diff=prev&oldid=936368512')
      expect(parser.revision_id).to eq(936368512)
    end

    it 'parses an old revision' do
      expect(parse('https://en.wikipedia.org/w/index.php?oldid=1315039613').revision_id)
        .to eq(1315039613)
    end

    it 'parses Special:Diff' do
      expect(parse('https://en.wikipedia.org/wiki/Special:Diff/1315039613').revision_id)
        .to eq(1315039613)
      expect(parse('https://en.wikipedia.org/wiki/Special:Diff/711811679/1178859026').revision_id)
        .to eq(711811679)
    end

    it 'parses Special:MobileDiff' do
      expect(parse('https://en.m.wikipedia.org/wiki/Special:MobileDiff/1315039613').revision_id)
        .to eq(1315039613)
    end

    it 'parses Special:PermanentLink' do
      expect(parse('https://en.wikipedia.org/wiki/Special:PermanentLink/1315039613').revision_id)
        .to eq(1315039613)
    end

    it 'parses Special:Diff given as an index.php title' do
      parser = parse('https://en.wikipedia.org/w/index.php?title=Special:Diff/1315039613')
      expect(parser.title).to be_nil
      expect(parser.revision_id).to eq(1315039613)
    end

    it 'parses Special:Diff typed as a title' do
      expect(parse('Special:Diff/1315039613').revision_id).to eq(1315039613)
    end

    it 'parses a page id link' do
      parser = parse('https://en.wikipedia.org/?curid=20408')
      expect(parser.title).to be_nil
      expect(parser.revision_id).to be_nil
      expect(parser.page_id).to eq(20408)
    end

    it 'parses an index.php page id link' do
      expect(parse('https://en.wikipedia.org/w/index.php?curid=20408').page_id).to eq(20408)
    end
  end

  describe 'URLs that name no page' do
    it 'returns nothing for a main page URL' do
      parser = parse('https://en.wikipedia.org/')
      expect([parser.title, parser.revision_id, parser.page_id]).to all(be_nil)
    end

    it 'returns nothing for a diff with no revision id' do
      parser = parse('https://en.wikipedia.org/w/index.php?diff=prev')
      expect([parser.title, parser.revision_id, parser.page_id]).to all(be_nil)
    end
  end
end
