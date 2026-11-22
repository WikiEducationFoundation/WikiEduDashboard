# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/wiki_edit_throttle"

describe WikiEditThrottle, :real_wiki_edit_throttle do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:user) { create(:user, username: 'ThrottledUser') }
  let(:turns) { [] }

  # Takes `count` turns in a row, recording when each one is granted.
  def take_turns(count, user: self.user, wiki: self.wiki, autoconfirmed: false)
    count.times do
      described_class.wait_for_turn(user:, wiki:, autoconfirmed:)
      turns << Time.zone.now
    end
  end

  def turns_within_a_minute_of_the_first
    turns.count { |turn| turn < turns.first + 60.seconds }
  end

  it 'lets the first edit through without waiting' do
    take_turns(1)
    expect(described_class).not_to have_received(:sleep)
  end

  it 'allows a user without the autoconfirmed right 7 edits per minute' do
    take_turns(10)
    expect(turns_within_a_minute_of_the_first).to eq(7)
  end

  it 'allows an autoconfirmed user 19 edits per minute' do
    take_turns(25, autoconfirmed: true)
    expect(turns_within_a_minute_of_the_first).to eq(19)
  end

  it 'does not make one user wait for another' do
    take_turns(1)
    take_turns(1, user: create(:user, username: 'OtherUser'))
    expect(described_class).not_to have_received(:sleep)
  end

  it 'does not make edits on one wiki wait for edits on another' do
    stub_wiki_validation
    take_turns(1)
    take_turns(1, wiki: Wiki.get_or_create(language: 'es', project: 'wikipedia'))
    expect(described_class).not_to have_received(:sleep)
  end

  it 'lets an edit straight through once the previous slot has passed' do
    take_turns(1)
    travel 10.seconds
    take_turns(1)
    expect(described_class).not_to have_received(:sleep)
  end
end
