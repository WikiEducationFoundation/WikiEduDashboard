# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/wikitext"

describe ArticleAuditing::Wikitext do
  let(:text) do
    "{{Infobox person|name={{nowrap|X}}}}\n'''X''' is notable.<ref name=\"a\">Src</ref>" \
      "<!-- hidden -->\n==Early life==\nBorn.<ref name=\"a\" />\n" \
      "=== Education ===\n{|\n|cell\n|}\nDone.\n"
  end
  let(:wikitext) { described_class.new(text) }

  it 'splits sections, with the lead first' do
    expect(wikitext.sections.map(&:title)).to eq([nil, 'Early life', 'Education'])
    expect(wikitext.sections.map(&:level)).to eq([1, 2, 3])
    expect(wikitext.lead.body).to include('is notable')
  end

  it 'masks templates, refs, comments and tables without changing offsets' do
    masked = wikitext.masked
    expect(masked.length).to eq(text.length)
    expect(masked).to include("'''X''' is notable.")
    expect(masked).not_to include('Infobox')
    expect(masked).not_to include('Src')
    expect(masked).not_to include('hidden')
    expect(masked).not_to include('cell')
    expect(masked.index('Done.')).to eq(text.index('Done.'))
  end

  it 'locates sections by character offset' do
    expect(wikitext.section_at(text.index('Born.')).title).to eq('Early life')
    expect(wikitext.section_at(text.index('Done.')).title).to eq('Education')
    expect(wikitext.section_at(0).title).to be_nil
    expect(wikitext.masked_body(wikitext.sections[1])).to start_with('Born.')
  end

  it 'counts ref tags' do
    expect(wikitext.ref_count).to eq(2)
  end

  it 'ignores headings in comments and sees headings followed by one' do
    text = "Lead.\n<!--\n== Hidden ==\n-->\n== Real == <!-- note -->\nBody.\n"
    sections = described_class.new(text).sections
    expect(sections.map(&:title)).to eq([nil, 'Real'])
    expect(sections.last.body).to eq("Body.\n")
    expect(sections.last.offset).to eq(text.index('Body.'))
  end

  it 'counts footnote templates as inline citations' do
    expect(described_class.new('Fact.{{sfn|Smith|2001|p=4}}').inline_citations?).to be true
    expect(described_class.new('Fact.{{r|smith}}').inline_citations?).to be true
    expect(described_class.new('Fact.<!-- <ref>x</ref> -->').inline_citations?).to be false
  end
end
