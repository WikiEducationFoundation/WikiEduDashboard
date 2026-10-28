# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_api/diff_wikitext_extractor"

describe WikiApi::DiffWikitextExtractor do
  # A diff row as action=compare renders it, with wikitext HTML-escaped.
  def diff_row(deleted, added)
    '<table><tr>' \
      "<td class=\"diff-deletedline\"><div>#{CGI.escapeHTML(deleted)}</div></td>" \
      "<td class=\"diff-addedline\"><div>#{added}</div></td></tr></table>"
  end

  def ins(text)
    "<ins class=\"diffchange diffchange-inline\">#{CGI.escapeHTML(text)}</ins>"
  end

  def changed_wikitext(deleted, added)
    described_class.new(diff_row(deleted, added)).changed_wikitext
  end

  let(:obscure) { "The early centuries of Aksum's development remain largely obscure." }
  let(:stone_age) { 'Stone Age artifacts have been unearthed at [[Lioness of Gobedra|Gobedra]].' }
  let(:reference) { '<ref>{{Cite journal |title=The Pre-Aksumite Period}}</ref>' }
  let(:new_sentence) do
    ' Archaeological research at Pre-Aksumite sites, such as [[Mezber]], has explored ' \
      'these early societies.'
  end

  # Based on https://en.wikipedia.org/w/index.php?diff=1382181955
  it 'extracts a sentence inserted mid-paragraph' do
    deleted = "#{obscure} #{stone_age}#{reference}"
    added = "#{CGI.escapeHTML(obscure)}#{ins("#{new_sentence}#{reference}")} " \
            "#{CGI.escapeHTML("#{stone_age}#{reference}")}"
    expect(changed_wikitext(deleted, added).strip).to eq("#{new_sentence}#{reference}".strip)
  end

  it 'extracts a sentence inserted after a cited sentence' do
    deleted = "#{obscure}#{reference} #{stone_age}"
    added = "#{CGI.escapeHTML("#{obscure}#{reference}")}#{ins(new_sentence)} " \
            "#{CGI.escapeHTML(stone_age)}"
    expect(changed_wikitext(deleted, added).strip).to eq(new_sentence.strip)
  end

  it 'extracts a sentence appended after a paragraph that ends with a citation' do
    deleted = "#{obscure}#{reference}"
    added = "#{CGI.escapeHTML("#{obscure}#{reference}")}#{ins(new_sentence)}"
    expect(changed_wikitext(deleted, added).strip).to eq(new_sentence.strip)
  end

  it 'extracts an inserted sentence that starts with a link' do
    sentence = ' [[Mezber]] is a Pre-Aksumite site.'
    deleted = "#{obscure} #{stone_age}"
    added = "#{CGI.escapeHTML(obscure)}#{ins(sentence)} #{CGI.escapeHTML(stone_age)}"
    expect(changed_wikitext(deleted, added).strip).to eq(sentence.strip)
  end

  it 'keeps the paragraph when an insertion ends mid-sentence' do
    deleted = "#{obscure} #{stone_age}"
    added = "#{CGI.escapeHTML(obscure)}#{ins(' Archaeological research at')} " \
            "#{CGI.escapeHTML(stone_age)}"
    expect(changed_wikitext(deleted, added)).to include('largely obscure')
  end

  it 'keeps the paragraph when one of several insertions is a fragment' do
    deleted = "#{obscure} #{stone_age}"
    added = "#{CGI.escapeHTML(obscure)}#{ins(new_sentence)} " \
            "Stone Age artifacts have been #{ins('recently ')}unearthed at " \
            '[[Lioness of Gobedra|Gobedra]].'
    expect(changed_wikitext(deleted, added)).to include('largely obscure')
  end

  it 'keeps the paragraph when an insertion follows a mid-sentence citation' do
    before = "#{obscure}#{reference} It traded with Rome,#{reference}"
    deleted = "#{before} India and China."
    added = "#{CGI.escapeHTML(before)}#{ins(' Persia, Arabia and Egypt.')} India and China."
    expect(changed_wikitext(deleted, added)).to include('largely obscure')
  end

  it 'keeps the paragraph when a mid-sentence citation follows a named reference' do
    before = "#{obscure}<ref name=\"aksum\" /> It traded with Rome,#{reference}"
    deleted = "#{before} India and China."
    added = "#{CGI.escapeHTML(before)}#{ins(' Persia, Arabia and Egypt.')} India and China."
    expect(changed_wikitext(deleted, added)).to include('largely obscure')
  end

  it 'keeps the paragraph when the insertion follows a sentence without final punctuation' do
    deleted = 'Aksum was a kingdom'
    added = "Aksum was a kingdom#{ins(' It traded with Rome.')}"
    expect(changed_wikitext(deleted, added)).to include('Aksum was a kingdom')
  end
end
