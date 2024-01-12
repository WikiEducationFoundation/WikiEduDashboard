# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('app/workers/update_wikidata_stats_worker')

describe UpdateWikidataStatsWorker do
  let(:course) { create(:course) }

  it 'starts a UpdateWikidataStats service' do
    expect(UpdateWikidataStats).to receive(:new)
    described_class.new.perform(course)
  end
end
