# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_library/judgment"

describe ClaimLibrary::Judgment do
  let(:source_text) do
    "Following a High Court decision allowing commercial surrogacy in 2002, the market\n" \
      'grew steadily. The Confederation of Indian Industry predicts that surrogacy ' \
      'generates US$2.3 billion annually.'
  end

  def judgment(**overrides)
    defaults = { verdict: 'full_support', reason: 'The figure is in the source.',
                 annotator: 'Moruri', passage: 'surrogacy generates US$2.3 billion annually' }
    described_class.new(**defaults.merge(overrides))
  end

  it 'accepts a verdict backed by a passage that is in the source' do
    expect(judgment.errors(source_text:)).to be_empty
  end

  it 'matches the passage regardless of line breaks and spacing' do
    passage = "the market\n   grew steadily"
    expect(judgment(passage:).errors(source_text:)).to be_empty
  end

  it 'rejects a passage that is not in the source' do
    errors = judgment(passage: 'thousands of IVF clinics').errors(source_text:)
    expect(errors).to eq(['passage was not found in the source text'])
  end

  it 'requires a passage unless the verdict is undetermined' do
    expect(judgment(passage: '').errors(source_text:))
      .to eq(['passage is required unless the verdict is undetermined'])
    expect(judgment(verdict: 'undetermined', passage: '').errors(source_text:)).to be_empty
  end

  it 'rejects a verdict the exercise does not offer' do
    expect(judgment(verdict: 'mostly_supports').errors(source_text:).first)
      .to start_with('verdict must be one of')
  end

  it 'rejects unknown flags and a missing reason or annotator' do
    errors = judgment(reason: '', annotator: ' ', flags: %w[time_drift vibes]).errors(source_text:)
    expect(errors).to include('reason is required', 'annotator is required',
                              'unknown flags: vibes')
  end

  it 'always records that the judgment was not AI assisted' do
    expect(judgment.to_h['ai_assisted']).to eq(false)
    expect(described_class.from_h(judgment.to_h.merge('ai_assisted' => true)).to_h['ai_assisted'])
      .to eq(false)
  end

  it 'survives a round trip through its hash form' do
    original = judgment(flags: ['true_but_unsupported'])
    restored = described_class.from_h(original.to_h)
    expect(restored.to_h).to eq(original.to_h)
  end
end
