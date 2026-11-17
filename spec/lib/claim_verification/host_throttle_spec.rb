# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/claim_verification/host_throttle"

describe ClaimVerification::HostThrottle do
  let(:throttle) { described_class.new(interval: 1.0) }

  before { allow(throttle).to receive(:sleep) }

  it 'waits between requests to the same host only' do
    throttle.wait('a.example')
    throttle.wait('b.example')
    expect(throttle).not_to have_received(:sleep)
    throttle.wait('a.example')
    expect(throttle).to have_received(:sleep).with(a_value_between(0.5, 1.0))
  end
end
