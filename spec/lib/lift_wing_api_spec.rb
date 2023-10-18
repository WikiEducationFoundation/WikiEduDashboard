# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/lift_wing_api"

describe LiftWingApi do
  let(:rev_ids) { [641962088, 675892696] }

  it 'returns the basically the same data as ORES used to', vcr: true do
    lift_wing_output = described_class.new(Wiki.first).get_revision_data rev_ids
    digger = ['enwiki', 'scores', '641962088', 'articlequality',
              'features', 'feature.english.stemmed.revision.stems_length']
    first_rev_liftwing = lift_wing_output.dig(*digger)
    expect(first_rev_liftwing).to be_positive
  end

  it 'handles TextDeleted revs similarly', vcr: true do
    lift_wing_output = described_class.new(Wiki.first).get_revision_data [708326238]
    # It doesn't need to have the exact same response,
    # but it does need the error type in the same place.
    digger = %w[enwiki scores 708326238 articlequality error type]
    expect(lift_wing_output.dig(*digger)).to include('TextDeleted')
  end
end
