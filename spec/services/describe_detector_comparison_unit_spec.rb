# frozen_string_literal: true

require 'rails_helper'

describe DescribeDetectorComparisonUnit do
  include_context 'detector comparison data'

  let(:result) { described_class.new(generated.id).result }

  it 'includes the text, the text as written, the prompts and the prior article link' do
    expect(result[:text]).to eq(generated_text)
    expect(result[:source_format]).to eq('model_reply')
    expect(result[:prompts].last).to eq('Start drafting your contributions')
    expect(result[:metadata]).not_to have_key('prompts')
    expect(result[:prior_article_url]).to eq('https://en.wikipedia.org/w/index.php?oldid=1011811699')
  end

  it 'describes each detector, including failed calls' do
    scores = result[:scores].index_by { |score| score[:check_type] }

    expect(scores['Pangram 4'][:windows].map { |window| window[:score] }).to eq([0.95, 0.25])
    expect(scores['Pangram 4'][:summary]['report_url']).to eq('https://www.pangram.com/history/abc')
    expect(scores['Originality AI Allowance 40'][:blocks]).to eq([{ ai: 1.0, status: 'success' }])
    expect(scores['Originality AI Allowance 15'][:error]).to eq('HTTP 402')
    expect(scores['Open Pangram EditLens Llama']).to include(imported: true)
  end

  it "cuts the text at Pangram's windows" do
    highlight = result[:highlight]

    expect(highlight).to include(check_type: 'Pangram 4', approximate: false)
    expect(highlight[:parts].map { |part| part[:window] }).to eq([0, 1])
    expect(highlight[:parts].map { |part| part[:text] }.join).to eq(generated_text)
  end

  it 'describes only units the page lists, naming the datasets that list them' do
    expect { described_class.new(retired.id) }.to raise_error(ActiveRecord::RecordNotFound)
    expect { described_class.new(other_agpedia.id) }.to raise_error(ActiveRecord::RecordNotFound)
    expect { described_class.new(repeated_baseline.id) }.to raise_error(ActiveRecord::RecordNotFound)
    expect(result[:datasets]).to eq(['topics'])
    expect(described_class.new(human.id).result[:datasets]).to eq(%w[topics known_human])
  end

  it 'marks each verdict that found AI' do
    scores = result[:scores].index_by { |score| score[:check_type] }

    expect(scores['Pangram 4']).to include(flagged: true)
    expect(described_class.new(human.id).result[:scores].first).to include(flagged: false)
  end
end
