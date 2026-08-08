# frozen_string_literal: true

require 'rails_helper'

describe LtiSetupProgress do
  it 'scores a full mark with the connected comment for a linked context' do
    progress = described_class.new(LtiContext.new(user_id: 1))
    expect(progress.score_given).to eq(1.0)
    expect(progress.score_maximum).to eq(1.0)
    expect(progress.comment).to eq(described_class::CONNECTED_COMMENT)
    expect(progress).to be_gradable
  end

  it 'scores zero with the not-connected comment for an unlinked context' do
    progress = described_class.new(LtiContext.new(user_id: nil))
    expect(progress.score_given).to eq(0.0)
    expect(progress.comment).to eq(described_class::NOT_CONNECTED_COMMENT)
    expect(progress).to be_gradable
  end

  it 'gives a distinct signature per connection state' do
    linked = described_class.new(LtiContext.new(user_id: 1))
    unlinked = described_class.new(LtiContext.new(user_id: nil))
    expect(linked.signature).not_to eq(unlinked.signature)
  end
end
