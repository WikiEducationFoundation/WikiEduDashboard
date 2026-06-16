# frozen_string_literal: true

require 'rails_helper'

describe HarvestVerificationClaimPoolWorker do
  it 'runs the pool harvester' do
    expect(HarvestVerificationClaimPool).to receive(:new)
    described_class.new.perform
  end
end
