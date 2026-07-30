# frozen_string_literal: true

require 'rails_helper'

describe RewriteLtiContentLinks do
  before do
    allow(ENV).to receive(:[]).and_call_original
    allow(ENV).to receive(:[]).with('dashboard_url').and_return('dashboard.wikiedu.org')
  end

  it 'adds target and rel to an external absolute link' do
    input = '<p><a href="https://en.wikipedia.org/wiki/Sandbox">sandbox</a></p>'
    output = described_class.new(input).html
    expect(output).to include('href="https://en.wikipedia.org/wiki/Sandbox"')
    expect(output).to include('target="_blank"')
    expect(output).to include('rel="noopener"')
  end

  it 'absolutizes a root-relative link against the Dashboard host' do
    input = '<a href="/training/students/sandboxes">sandboxes</a>'
    output = described_class.new(input).html
    expect(output).to include(
      'href="https://dashboard.wikiedu.org/training/students/sandboxes"'
    )
  end

  it 'adds target and rel to a root-relative link' do
    input = '<a href="/training/students/sandboxes">sandboxes</a>'
    output = described_class.new(input).html
    expect(output).to include('target="_blank"')
    expect(output).to include('rel="noopener"')
  end

  it 'absolutizes a relative link against the Dashboard host' do
    input = '<a href="courses/School/Course_(term)">course</a>'
    output = described_class.new(input).html
    expect(output).to include('href="https://dashboard.wikiedu.org/courses/School/Course_(term)"')
  end

  it 'leaves a fragment-only link untouched' do
    input = '<a href="#week-2">week 2</a>'
    output = described_class.new(input).html
    expect(output).to eq(input)
  end

  it 'leaves an anchor without an href untouched' do
    input = '<a name="week-2">week 2</a>'
    output = described_class.new(input).html
    expect(output).to eq(input)
  end

  it 'passes link-free content through unchanged' do
    input = '<p>Complete the <strong>Evaluating Articles</strong> training.</p>'
    output = described_class.new(input).html
    expect(output).to eq(input)
  end

  it 'does not duplicate existing target and rel attributes' do
    input = '<a href="https://example.com" target="_blank" rel="noopener">out</a>'
    output = described_class.new(input).html
    expect(output.scan('target=').count).to eq(1)
    expect(output.scan('rel=').count).to eq(1)
  end

  it 'leaves an unparseable href untouched apart from retargeting' do
    input = '<a href="https://example.com/a b">broken</a>'
    output = described_class.new(input).html
    # Nokogiri's serializer percent-encodes the space; the href is otherwise
    # not rewritten.
    expect(output).to include('href="https://example.com/a%20b"')
    expect(output).to include('target="_blank"')
  end

  it 'leaves a relative href alone when no dashboard_url is configured' do
    allow(ENV).to receive(:[]).with('dashboard_url').and_return(nil)
    input = '<a href="/training/students">trainings</a>'
    output = described_class.new(input).html
    expect(output).to include('href="/training/students"')
    expect(output).to include('target="_blank"')
  end
end
