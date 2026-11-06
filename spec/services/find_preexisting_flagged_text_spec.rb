# frozen_string_literal: true

require 'rails_helper'

describe FindPreexistingFlaggedText do
  let(:wiki) { Wiki.default_wiki }
  let(:old_paragraph) do
    'Stone Age artifacts have been unearthed at Gobedra. Two hills lie east of the city.'
  end
  let(:new_sentence) { 'Archaeological research has explored these early societies.' }
  let(:parent_text) { "Aksum was a kingdom.\n\n#{old_paragraph}[12]\n\nLater history." }

  def window(text, score)
    { 'text' => text, 'ai_assistance_score' => score }
  end

  def find(windows, parent_rev_id: 100)
    described_class.new(windows:, text: windows.map { |w| w['text'] }.join,
                        parent_rev_id:, wiki:, threshold: 0.9)
  end

  before do
    allow(GetRevisionPlaintext).to receive(:new)
      .with(100, wiki, diff_mode: false)
      .and_return(instance_double(GetRevisionPlaintext, plain_text: parent_text))
  end

  it 'is all pre-existing when every flagged window was in the parent revision' do
    result = find([window(new_sentence, 0.1), window("#{old_paragraph}[1]", 0.99)])
    expect(result.all_preexisting?).to be true
  end

  it 'is not all pre-existing when a flagged window includes new text' do
    result = find([window("#{new_sentence} #{old_paragraph}", 0.99)])
    expect(result.all_preexisting?).to be false
  end

  it 'compares each paragraph of a window separately' do
    result = find([window("Aksum was a kingdom.\n\n#{old_paragraph}", 0.99)])
    expect(result.all_preexisting?).to be true
  end

  it 'reports which flagged passages were pre-existing' do
    result = find([window("#{new_sentence}\n#{old_paragraph}", 0.99)])
    expect(result.flagged_passages).to eq([new_sentence, old_paragraph])
    expect(result.preexisting_passages).to eq([old_paragraph])
  end

  it 'uses window offsets when the window has no text' do
    windows = [{ 'start_index' => 0, 'end_index' => old_paragraph.length,
                 'ai_assistance_score' => 0.99 }]
    result = described_class.new(windows:, text: "#{old_paragraph} #{new_sentence}",
                                 parent_rev_id: 100, wiki:, threshold: 0.9)
    expect(result.all_preexisting?).to be true
  end

  it 'does not fetch a parent for a page creation' do
    expect(GetRevisionPlaintext).not_to receive(:new)
    expect(find([window(old_paragraph, 0.99)], parent_rev_id: 0).all_preexisting?).to be false
  end

  it 'is not all pre-existing when nothing was flagged' do
    expect(find([window(old_paragraph, 0.5)]).all_preexisting?).to be false
  end
end
