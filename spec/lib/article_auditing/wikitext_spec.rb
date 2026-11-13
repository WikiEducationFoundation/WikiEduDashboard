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

  it 'counts ref tags' do
    expect(wikitext.ref_count).to eq(2)
  end
end
