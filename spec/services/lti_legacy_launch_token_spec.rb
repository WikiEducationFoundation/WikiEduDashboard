# frozen_string_literal: true

require 'rails_helper'

describe LtiLegacyLaunchToken do
  let(:idtoken) { { 'ltiVersion' => '1.2.0', 'user' => { 'id' => 'canvas-user' } } }

  it 'round-trips the idtoken it was given' do
    expect(described_class.decode(described_class.encode(idtoken))).to eq(idtoken)
  end

  # The prefix is how LtiSession tells our token from an LTIAAS ltik without
  # attempting a decode first.
  it 'marks its own tokens and disclaims anything else' do
    expect(described_class.ours?(described_class.encode(idtoken))).to be true
    expect(described_class.ours?('an-ltiaas-ltik')).to be false
    expect(described_class.ours?(nil)).to be false
  end

  it 'refuses a token past its lifetime' do
    token = described_class.encode(idtoken)
    travel_to((described_class::LIFETIME + 1.minute).from_now) do
      expect { described_class.decode(token) }.to raise_error(described_class::Expired)
    end
  end

  it 'still accepts a token inside its lifetime' do
    token = described_class.encode(idtoken)
    travel_to(23.hours.from_now) do
      expect(described_class.decode(token)).to eq(idtoken)
    end
  end

  it 'refuses a token that names no launch' do
    expect { described_class.decode("#{described_class::PREFIX}made-up") }
      .to raise_error(described_class::Invalid)
    expect { described_class.decode(nil) }.to raise_error(described_class::Invalid)
  end

  # Server-side state, so a launch can be revoked — which a self-contained
  # token could not be.
  it 'refuses a token whose launch has been swept away' do
    token = described_class.encode(idtoken)
    LtiLegacyLaunch.delete_all
    expect { described_class.decode(token) }.to raise_error(described_class::Invalid)
  end

  # The token has to fit in a session cookie: LtiLaunchController#connect_course
  # stashes it there for the Wikipedia OAuth break-out, and a token carrying the
  # whole idtoken overflowed the 4 KB limit against real Canvas.
  it 'is short enough to stash in a session cookie' do
    expect(described_class.encode(idtoken).length).to be < 100
  end

  it 'sweeps launches that are past their lifetime' do
    described_class.encode(idtoken)
    travel_to((described_class::LIFETIME + 1.minute).from_now) do
      described_class.encode(idtoken)
    end
    expect(LtiLegacyLaunch.count).to eq(1)
  end
end
