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

  it 'leaves text after the last of several windows unmarked' do
    segments = described_class.new(text, [window(0, 8), window(8, 14)])

    expect(segments.parts.map { |part| part[:window] }).to eq([0, 1, nil])
    expect(segments.approximate?).to be(false)
  end

  it 'stretches a lone window that ends short over the whole text' do
    segments = described_class.new(text, [window(0, 40)])

    expect(segments.parts).to eq([{ text:, window: 0 }])
    expect(segments.approximate?).to be(false)
  end

  it 'scales offsets that run past the text and moves cuts to a space' do
    segments = described_class.new(text, [window(0, 30), window(30, 80)])

    expect(segments.approximate?).to be(true)
    expect(segments.parts.map { |part| part[:text] }.join).to eq(text)
    expect(segments.parts.first[:text]).to end_with(' ')
  end

  it 'has no parts without offsets' do
    expect(described_class.new(text, [{ 'ai_assistance_score' => 0.5 }]).parts).to be_empty
  end
end
