# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/wiki_url_parser"

describe WikiUrlParser do
  # Non-diff
  let(:revision_title_url) { 'https://en.wikipedia.org/w/index.php?title=List_of_the_busiest_airports_in_Malaysia&oldid=1276659876' }
  let(:article_url) { 'https://en.wikipedia.org/wiki/Greater_Cooch_Behar_People%27s_Association' }
  let(:revision_url) { 'https://en.wikipedia.org/w/index.php?oldid=1315039613' }
  # Diff
  let(:diff_prev_url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512' }
  let(:diff_range_url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=1178859026&oldid=711811679' }
  let(:diff_title_url) { 'https://en.wikipedia.org/w/index.php?title=List_of_hystricids&diff=1315039613' }
  let(:diff_url) { 'https://en.wikipedia.org/w/index.php?diff=1315039613' }

  it 'handles a view url for a single revision that contains title' do
    parser = described_class.new(revision_title_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'List of the busiest airports in Malaysia'
    expect(parser.oldid).to eq 1276659876
    expect(parser.diff).to be_nil
  end

  it 'handles an article url' do
    parser = described_class.new(article_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq "Greater Cooch Behar People's Association"
    expect(parser.oldid).to be_nil
    expect(parser.diff).to be_nil
  end

  it 'handles a view url for a single revision without article title' do
    parser = described_class.new(revision_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to be_nil
    expect(parser.oldid).to eq 1315039613
    expect(parser.diff).to be_nil
  end

  it 'handles a prev diff url' do
    parser = described_class.new(diff_prev_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'Richard G. F. Uniacke'
    expect(parser.oldid).to eq 936368512
    expect(parser.diff).to be_nil
    expect(parser.prev_diff?).to be true
  end

  it 'handles a diff range url' do
    parser = described_class.new(diff_range_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'Richard G. F. Uniacke'
    expect(parser.oldid).to eq 711811679
    expect(parser.diff).to eq 1178859026
  end

  it 'handles a diff url that contains article title' do
    parser = described_class.new(diff_title_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'List of hystricids'
    expect(parser.oldid).to be_nil
    expect(parser.diff).to eq 1315039613
  end

  it 'handles a diff url that without article title' do
    parser = described_class.new(diff_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to be_nil
    expect(parser.oldid).to be_nil
    expect(parser.diff).to eq 1315039613
  end

  it 'returns nils if it is not a valid wiki' do
    parser = described_class.new('https://www.wikiedu.org/')
    expect(parser.wiki).to be_nil
    expect(parser.title).to be_nil
    expect(parser.oldid).to be_nil
    expect(parser.diff).to be_nil
  end

  describe '#revision_target' do
    it 'targets the text added between the two revisions of a diff range' do
      url = 'https://en.wikipedia.org/w/index.php?diff=1178859026&oldid=711811679'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1178859026, from_rev: 711811679, diff_mode: true)
    end

    it 'targets a single edit against its parent when only diff is given' do
      url = 'https://en.wikipedia.org/w/index.php?diff=1315039613'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1315039613, from_rev: nil, diff_mode: true)
    end

    it 'targets the whole revision when only oldid is given' do
      url = 'https://en.wikipedia.org/w/index.php?oldid=1009773007'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1009773007, from_rev: nil, diff_mode: false)
    end

    it 'targets the edit against its parent for diff=prev, not the whole article' do
      url = 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 936368512, from_rev: nil, diff_mode: true)
    end

    it 'is nil for diff=next, which cannot be resolved without the API' do
      url = 'https://en.wikipedia.org/w/index.php?title=Some_Title&diff=next&oldid=936368512'
      expect(described_class.new(url).revision_target).to be_nil
    end

    it 'distinguishes an unresolvable revision selector from a plain page URL' do
      with_next = 'https://en.wikipedia.org/w/index.php?title=T&diff=next&oldid=5'
      page_only = 'https://en.wikipedia.org/wiki/Some_Title'
      oldid_only = 'https://en.wikipedia.org/w/index.php?oldid=5'
      expect(described_class.new(with_next).revision_selector?).to be true
      expect(described_class.new(page_only).revision_selector?).to be false
      expect(described_class.new(oldid_only).revision_selector?).to be true
    end

    it 'is nil for a page title URL' do
      parser = described_class.new('https://en.wikipedia.org/wiki/Some_Title')
      expect(parser.revision_target).to be_nil
    end

    it 'targets a Special:Diff range like the equivalent diff URL' do
      url = 'https://en.wikipedia.org/wiki/Special:Diff/711811679/1178859026'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1178859026, from_rev: 711811679, diff_mode: true)
    end

    it 'targets a single Special:Diff edit against its parent' do
      url = 'https://en.wikipedia.org/wiki/Special:Diff/1315039613'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1315039613, from_rev: nil, diff_mode: true)
    end

    it 'targets the whole revision for Special:PermanentLink' do
      url = 'https://en.wikipedia.org/wiki/Special:PermanentLink/1009773007'
      target = described_class.new(url).revision_target
      expect(target).to eq(rev_id: 1009773007, from_rev: nil, diff_mode: false)
    end
  end

  describe '#wiki' do
    it 'reads a mobile host' do
      wiki = described_class.new('https://en.m.wikipedia.org/wiki/Marie_Curie').wiki
      expect([wiki.language, wiki.project]).to eq(%w[en wikipedia])
    end

    it 'reads a URL without a scheme' do
      wiki = described_class.new('en.wikipedia.org/wiki/Marie_Curie').wiki
      expect([wiki.language, wiki.project]).to eq(%w[en wikipedia])
    end
  end

  describe '#title in /wiki/ URLs' do
    def title(url)
      described_class.new(url).title
    end

    it 'parses an http URL' do
      expect(title('http://en.wikipedia.org/wiki/Marie_Curie')).to eq('Marie Curie')
    end

    it 'parses a mobile URL' do
      expect(title('https://en.m.wikipedia.org/wiki/Marie_Curie')).to eq('Marie Curie')
    end

    it 'drops a section fragment' do
      expect(title('https://en.wikipedia.org/wiki/Marie_Curie#Early_life')).to eq('Marie Curie')
    end

    it 'drops the mobile editor fragment' do
      expect(title('https://en.m.wikipedia.org/wiki/Marie_Curie#/editor/0')).to eq('Marie Curie')
    end

    it 'drops a query string' do
      expect(title('https://en.wikipedia.org/wiki/Marie_Curie?veaction=edit')).to eq('Marie Curie')
    end

    it 'prefers the title in the path to one in the query' do
      expect(title('https://en.wikipedia.org/wiki/Marie_Curie?title=Selfie')).to eq('Marie Curie')
    end

    it 'decodes percent-encoding' do
      expect(title('https://es.wikipedia.org/wiki/Jalape%C3%B1o')).to eq('Jalapeño')
      expect(title('https://en.wikipedia.org/wiki/Selfie_%28photography%29'))
        .to eq('Selfie (photography)')
    end

    it 'decodes an escaped question mark in the title' do
      expect(title('https://en.wikipedia.org/wiki/What%27s_the_411%3F')).to eq("What's the 411?")
    end

    it 'keeps a literal plus in the path' do
      expect(title('https://en.wikipedia.org/wiki/C++')).to eq('C++')
      expect(title('https://en.wikipedia.org/wiki/C%2B%2B')).to eq('C++')
    end

    it 'parses a URL with unencoded non-ASCII characters' do
      expect(title('https://es.wikipedia.org/wiki/Jalapeño')).to eq('Jalapeño')
    end
  end

  describe '#title in /w/index.php URLs' do
    def title(url)
      described_class.new(url).title
    end

    it 'parses a section edit URL' do
      url = 'https://en.wikipedia.org/w/index.php?title=Marie_Curie&action=edit&section=2'
      expect(title(url)).to eq('Marie Curie')
    end

    it 'parses a history URL' do
      url = 'https://en.wikipedia.org/w/index.php?title=Marie_Curie&action=history'
      expect(title(url)).to eq('Marie Curie')
    end

    it 'parses a URL where the title is not the first parameter' do
      url = 'https://en.wikipedia.org/w/index.php?action=edit&title=Marie_Curie'
      expect(title(url)).to eq('Marie Curie')
    end

    it 'parses a mobile redlink URL' do
      url = 'https://en.m.wikipedia.org/w/index.php?title=Red_link&action=edit&redlink=1'
      expect(title(url)).to eq('Red link')
    end

    it 'decodes a title with parentheses and non-ASCII characters' do
      url = 'https://en.wikipedia.org/w/index.php?title=Smedsb%C3%B6le_Radio_Mast_%28Finland%29&oldid=1'
      expect(title(url)).to eq('Smedsböle Radio Mast (Finland)')
    end

    it 'reads a plus in the query as a space' do
      url = 'https://en.wikipedia.org/w/index.php?title=Marie+Curie&action=edit'
      expect(title(url)).to eq('Marie Curie')
    end

    it 'reads an escaped plus in the query as a plus' do
      url = 'https://en.wikipedia.org/w/index.php?title=C%2B%2B&action=edit'
      expect(title(url)).to eq('C++')
    end

    it 'reads an escaped ampersand in the title' do
      url = 'https://en.wikipedia.org/w/index.php?title=AT%26T&action=edit'
      expect(title(url)).to eq('AT&T')
    end
  end

  describe 'Special: revision pages' do
    it 'reads Special:Diff with one id as diff=' do
      parser = described_class.new('https://en.wikipedia.org/wiki/Special:Diff/1315039613')
      expect([parser.title, parser.oldid, parser.diff]).to eq([nil, nil, 1315039613])
    end

    it 'reads Special:Diff with two ids as oldid= and diff=' do
      parser = described_class.new('https://en.wikipedia.org/wiki/Special:Diff/711811679/1178859026')
      expect([parser.oldid, parser.diff]).to eq([711811679, 1178859026])
    end

    it 'reads Special:Diff against the previous revision' do
      parser = described_class.new('https://en.wikipedia.org/wiki/Special:Diff/936368512/prev')
      expect(parser.oldid).to eq(936368512)
      expect(parser.prev_diff?).to be true
    end

    it 'reads Special:MobileDiff, with one id or a range' do
      single = described_class.new('https://en.m.wikipedia.org/wiki/Special:MobileDiff/1315039613')
      range = described_class.new('https://en.m.wikipedia.org/wiki/Special:MobileDiff/711811679...1178859026')
      expect(single.diff).to eq(1315039613)
      expect([range.oldid, range.diff]).to eq([711811679, 1178859026])
    end

    it 'reads Special:PermanentLink as oldid=' do
      parser = described_class.new('https://en.wikipedia.org/wiki/Special:PermanentLink/1315039613')
      expect([parser.oldid, parser.diff]).to eq([1315039613, nil])
    end

    it 'reads Special:Diff given as an index.php title' do
      parser = described_class.new('https://en.wikipedia.org/w/index.php?title=Special:Diff/1315039613')
      expect([parser.title, parser.diff]).to eq([nil, 1315039613])
    end

    it 'reads Special:Diff given as a page name' do
      parser = described_class.for_page_name('Special:Diff/1315039613')
      expect([parser.title, parser.diff]).to eq([nil, 1315039613])
    end
  end

  describe '#curid' do
    it 'reads a page id link' do
      parser = described_class.new('https://en.wikipedia.org/?curid=20408')
      expect([parser.title, parser.curid]).to eq([nil, 20408])
    end

    it 'reads an index.php page id link' do
      expect(described_class.new('https://en.wikipedia.org/w/index.php?curid=20408').curid)
        .to eq(20408)
    end
  end
end
