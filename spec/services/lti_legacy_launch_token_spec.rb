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

  it 'refuses a tampered token' do
    token = described_class.encode(idtoken)
    expect { described_class.decode("#{token}x") }.to raise_error(described_class::Invalid)
  end

  it 'refuses a token signed with a different secret' do
    other = JWT.encode({ 'idt' => idtoken, 'exp' => 1.hour.from_now.to_i }, 'other', 'HS256')
    expect { described_class.decode("#{described_class::PREFIX}#{other}") }
      .to raise_error(described_class::Invalid)
  end

  it 'refuses a well-signed token that carries no idtoken' do
    payload = JWT.encode({ 'exp' => 1.hour.from_now.to_i }, described_class.secret, 'HS256')
    expect { described_class.decode("#{described_class::PREFIX}#{payload}") }
      .to raise_error(described_class::Invalid)
  end
end
