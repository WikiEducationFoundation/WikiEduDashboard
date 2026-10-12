# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/ai/pangram_window_segments"

describe PangramWindowSegments do
  let(:text) { 'one two three four five six seven eight nine ten' }

  def window(start_index, end_index)
    { 'start_index' => start_index, 'end_index' => end_index }
  end

  it 'cuts the text exactly when the last window ends at its end' do
    segments = described_class.new(text, [window(0, 14), window(14, text.length)])

    expect(segments.parts).to eq([{ text: 'one two three ', window: 0 },
                                  { text: text[14..], window: 1 }])
    expect(segments.approximate?).to be(false)
  end

  it 'leaves text outside every window unmarked' do
    segments = described_class.new(text, [window(4, 14)])

    expect(segments.parts.map { |part| part[:window] }).to eq([nil, 0])
  end

  it 'scales offsets to a text of a different length and moves cuts to a space' do
    segments = described_class.new(text, [window(0, 12), window(12, 40)])

    expect(segments.approximate?).to be(true)
    expect(segments.parts.map { |part| part[:text] }.join).to eq(text)
    expect(segments.parts.first[:text]).to end_with(' ')
  end

  it 'has no parts without offsets' do
    expect(described_class.new(text, [{ 'ai_assistance_score' => 0.5 }]).parts).to be_empty
  end
end
