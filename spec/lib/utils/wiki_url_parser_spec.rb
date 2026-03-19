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
    expect(parser.title).to eq 'List_of_the_busiest_airports_in_Malaysia'
    expect(parser.oldid).to eq 1276659876
    expect(parser.diff).to be_nil
  end

  it 'handles an article url' do
    parser = described_class.new(article_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'Greater_Cooch_Behar_People%27s_Association'
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
    expect(parser.title).to eq 'Richard_G._F._Uniacke'
    expect(parser.oldid).to eq 936368512
    expect(parser.diff).to eq 0
  end

  it 'handles a diff range url' do
    parser = described_class.new(diff_range_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'Richard_G._F._Uniacke'
    expect(parser.oldid).to eq 711811679
    expect(parser.diff).to eq 1178859026
  end

  it 'handles a diff url that contains article title' do
    parser = described_class.new(diff_title_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'List_of_hystricids'
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
end
