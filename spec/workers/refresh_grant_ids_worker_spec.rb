# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/app/workers/refresh_grant_ids_worker"

describe RefreshGrantIdsWorker do
  before do
    allow(GrantIdList).to receive(:configured?).and_return(true)
    allow(GrantIdList).to receive(:refresh).and_return(3)
  end

  it 'refreshes the grant IDs on P&E' do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    described_class.new.perform
    expect(GrantIdList).to have_received(:refresh)
  end

  it 'does nothing on Wiki Ed' do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    described_class.new.perform
    expect(GrantIdList).not_to have_received(:refresh)
  end

  it 'does nothing when no spreadsheet is configured' do
    allow(Features).to receive(:wiki_ed?).and_return(false)
    allow(GrantIdList).to receive(:configured?).and_return(false)
    described_class.new.perform
    expect(GrantIdList).not_to have_received(:refresh)
  end
end
