# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/wikiwho_passage_attributor"

describe WikiWhoPassageAttributor do
  # Splits wikitext into WikiWho-style tokens (lowercased words, punctuation
  # and markup), each attributed to rev_id.
  def tokens(wikitext, rev_id)
    wikitext.downcase.scan(/\[\[|\]\]|\{\{|\}\}|[[:word:]]+|[^[:word:]\s]/)
            .map { |str| { 'str' => str, 'o_rev_id' => rev_id, 'editor' => '1' } }
  end

  let(:article_tokens) do
    tokens('Aksum was a kingdom. ', 1) +
      tokens('Stone Age artifacts have been unearthed at [[Lioness of Gobedra|Gobedra]], ', 2) +
      tokens('<ref>{{cite book |title=Stone Age artifacts of Gobedra}}</ref>', 3) +
      tokens('two kilometres west of [[Aksum]]. ', 4) +
      tokens('Two hills lie east of the city.<ref name="x" />', 5)
  end

  it 'counts words by the revision that added them' do
    passage = 'Stone Age artifacts have been unearthed at Gobedra, two kilometres west of Aksum.'
    counts = described_class.new(passages: [passage], tokens: article_tokens).word_counts
    expect(counts).to eq(2 => 8, 4 => 5)
  end

  it 'skips references and templates' do
    passage = 'Two hills lie east of the city.'
    counts = described_class.new(passages: [passage], tokens: article_tokens).word_counts
    expect(counts).to eq(5 => 7)
  end

  it 'combines counts across passages' do
    passages = ['Aksum was a kingdom.', 'Two hills lie east of the city.']
    counts = described_class.new(passages:, tokens: article_tokens).word_counts
    expect(counts).to eq(1 => 4, 5 => 7)
  end

  it 'ignores a passage it cannot find' do
    passage = 'This sentence is not in the article at all.'
    counts = described_class.new(passages: [passage], tokens: article_tokens).word_counts
    expect(counts).to be_empty
  end
end
