# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/training/training_yaml_editor"

describe TrainingYamlEditor do
  let(:text) do
    <<~YAML
      ---
      title: "Old title"
      id: 101
      # The quiz stays as it is.
      assessment:
        question: Why?
      content: |
        First paragraph.

        Second paragraph.

      # Trailing comment
    YAML
  end

  it 'leaves the text unchanged when nothing is set' do
    expect(described_class.new(text).to_s).to eq(text)
  end

  it 'rewrites only the changed key, keeping comments and other formatting' do
    editor = described_class.new(text)
    editor.set('title', 'New title')
    expect(editor.to_s).to eq(text.sub('title: "Old title"', 'title: New title'))
  end

  it 'writes multi-line text as a literal block and keeps the comments after it' do
    editor = described_class.new(text)
    editor.set('content', "New paragraph.\n")
    expect(editor.to_s).to end_with("content: |\n  New paragraph.\n\n# Trailing comment\n")
  end

  it 'keeps markdown line breaks and tabs in a literal block' do
    editor = described_class.new(text)
    editor.set('content', "Line one  \n\tindented\n")
    expect(editor.to_s).to include("content: |\n  Line one  \n  \tindented\n")
    expect(YAML.safe_load(editor.to_s)['content']).to eq("Line one  \n\tindented\n")
  end

  it 'appends keys the document did not have' do
    editor = described_class.new(text)
    editor.set('button_text', 'Okay')
    expect(editor.to_s).to start_with(text)
    expect(YAML.safe_load(editor.to_s)['button_text']).to eq('Okay')
  end

  it 'exposes the original text of a key' do
    expect(described_class.new(text).original_text('assessment'))
      .to eq("assessment:\n  question: Why?\n")
  end

  it 're-dumps the whole document when splicing would lose another value' do
    # A quoted key isn't recognised as the start of a key, so it is spliced
    # away along with the value before it.
    editor = described_class.new(%(id: 1\n"name": Pond\n))
    editor.set('id', 2)
    expect(YAML.safe_load(editor.to_s)).to eq('id' => 2, 'name' => 'Pond')
  end

  describe '.emit' do
    it 'marks text without a final newline with strip chomping' do
      expect(described_class.emit('content', "a\nb")).to eq("content: |-\n  a\n  b\n")
    end

    it 'marks text with extra final newlines with keep chomping' do
      block = described_class.emit('content', "a\n\n")
      expect(YAML.safe_load(block)).to eq('content' => "a\n\n")
    end

    it 'gives an indentation indicator when the first line starts with spaces' do
      block = described_class.emit('content', "  code\nmore\n")
      expect(block).to start_with("content: |2\n")
      expect(YAML.safe_load(block)).to eq('content' => "  code\nmore\n")
    end

    it 'falls back to a quoted scalar for text a literal block cannot hold' do
      value = "bell \a\nnext\n"
      expect(YAML.safe_load(described_class.emit('content', value))).to eq('content' => value)
    end
  end
end
