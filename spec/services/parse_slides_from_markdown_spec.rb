# frozen_string_literal: true

require 'rails_helper'

describe ParseSlidesFromMarkdown do
  it 'parses a simple two-slide paste' do
    markdown = <<~MD
      ## Introduction
      Welcome to the module.

      ## Why it matters
      Here is why it matters.
    MD

    slides = described_class.new(markdown).slides
    expect(slides.length).to eq(2)
    expect(slides[0]).to include('title' => 'Introduction', 'slug' => 'introduction')
    expect(slides[0]['content']).to eq("Welcome to the module.\n")
    expect(slides[1]).to include('title' => 'Why it matters', 'slug' => 'why-it-matters')
  end

  it 'parameterizes titles with punctuation' do
    slides = described_class.new("## Five Pillars: Quiz!\nQ").slides
    expect(slides.first['slug']).to eq('five-pillars-quiz')
  end

  it 'supports title-only slides (empty content)' do
    slides = described_class.new("## Just a title").slides
    expect(slides.first['content']).to eq('')
  end

  it 'raises when input does not start with a heading' do
    expect { described_class.new("Some prose\n## Heading\ncontent").slides }
      .to raise_error(ParseSlidesFromMarkdown::InvalidFormat)
  end

  it 'accepts h1 as the slide boundary when it appears first' do
    markdown = "# Intro\nBody one.\n\n# Second\nBody two.\n"
    parser = described_class.new(markdown)
    expect(parser.heading_level).to eq(1)
    expect(parser.slides.map { |s| s['title'] }).to eq(%w[Intro Second])
  end

  it 'treats the non-boundary level as content when both h1 and h2 appear' do
    markdown = "# First\ncontent\n## Not a boundary\nmore content\n# Second\nbody\n"
    parser = described_class.new(markdown)
    expect(parser.slides.length).to eq(2)
    expect(parser.slides.first['content']).to include('## Not a boundary')
  end

  it 'locks in h2 when it is the first heading level seen' do
    markdown = "## First\ncontent\n# Still content\nmore\n## Second\nbody\n"
    parser = described_class.new(markdown)
    expect(parser.heading_level).to eq(2)
    expect(parser.slides.length).to eq(2)
    expect(parser.slides.first['content']).to include('# Still content')
  end

  it 'raises on empty input' do
    expect { described_class.new('').slides }
      .to raise_error(ParseSlidesFromMarkdown::InvalidFormat)
  end

  it 'ignores ## lines inside fenced code blocks' do
    markdown = <<~MD
      ## Real heading
      Intro text.

      ```
      ## This is not a heading
      ```

      more text.
    MD

    slides = described_class.new(markdown).slides
    expect(slides.length).to eq(1)
    expect(slides.first['content']).to include('## This is not a heading')
  end

  it 'preserves intra-slide blank lines' do
    markdown = "## Heading\nparagraph one\n\nparagraph two\n"
    slides = described_class.new(markdown).slides
    expect(slides.first['content']).to eq("paragraph one\n\nparagraph two\n")
  end

  it 'does not treat ### or deeper headings as slide separators' do
    markdown = "## Top\ncontent\n### Subheading\nmore content\n"
    slides = described_class.new(markdown).slides
    expect(slides.length).to eq(1)
    expect(slides.first['content']).to include('### Subheading')
  end

  it 'does not treat ### as a slide boundary when h1 is the chosen level either' do
    markdown = "# Top\ncontent\n### Subheading\nmore content\n"
    slides = described_class.new(markdown).slides
    expect(slides.length).to eq(1)
    expect(slides.first['content']).to include('### Subheading')
  end

  it 'recognizes setext-style H1 headings (Google Docs copy-as-markdown)' do
    markdown = <<~MD
      What is an LLM?
      ===============

      The core components of AI services...

      Context window
      ==============

      When a chatbot generates text...
    MD
    parser = described_class.new(markdown)
    expect(parser.heading_level).to eq(1)
    expect(parser.slides.map { |s| s['title'] }).to eq(['What is an LLM?', 'Context window'])
    expect(parser.slides.first['content']).to include('The core components of AI services...')
  end

  it 'recognizes setext-style H2 headings' do
    markdown = "Intro\n-----\n\nFirst body.\n\nNext\n-----\n\nSecond body.\n"
    parser = described_class.new(markdown)
    expect(parser.heading_level).to eq(2)
    expect(parser.slides.map { |s| s['title'] }).to eq(%w[Intro Next])
  end

  it 'does not misinterpret inline --- em dashes as setext underlines' do
    markdown = "# Title\nAI services --- like ChatGPT --- are common.\n"
    slides = described_class.new(markdown).slides
    expect(slides.length).to eq(1)
    expect(slides.first['content']).to include('AI services --- like ChatGPT')
  end
end
