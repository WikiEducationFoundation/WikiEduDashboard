# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/utils/wiki_url_parser"

describe WikiUrlParser do
  let(:revision_url) { 'https://en.wikipedia.org/w/index.php?title=List_of_the_busiest_airports_in_Malaysia&oldid=1276659876' }
  let(:prev_url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=prev&oldid=936368512' }
  let(:diff_range_url) { 'https://en.wikipedia.org/w/index.php?title=Richard_G._F._Uniacke&diff=1178859026&oldid=711811679'}

  it 'handles a view url for a single revision' do
    parser = described_class.new(revision_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'List_of_the_busiest_airports_in_Malaysia'
    expect(parser.oldid).to eq 1276659876
    expect(parser.diff).to be_nil
  end

  it 'handles a prev diff url' do
    parser = described_class.new(prev_url)
    wiki = parser.wiki
    expect(wiki.language).to eq 'en'
    expect(wiki.project).to eq 'wikipedia'
    expect(parser.title).to eq 'Richard_G._F._Uniacke'
    expect(parser.oldid).to eq 936368512
    expect(parser.diff).to be_nil
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

  it 'returns nils if it is not a valid wiki' do
    parser = described_class.new('https://www.wikiedu.org/')
    expect(parser.wiki).to be_nil
    expect(parser.title).to be_nil
    expect(parser.oldid).to be_nil
    expect(parser.diff).to be_nil
  end
end
