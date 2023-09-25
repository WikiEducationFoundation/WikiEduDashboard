# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/lift_wing_api"
require "#{Rails.root}/lib/ores_api"

describe LiftWingApi do
  let(:rev_ids) { [641962088, 675892696] }

  it 'returns the basically the same data as OresApi', vcr: true do
    ores_output = OresApi.new(Wiki.first).get_revision_data rev_ids
    lift_wing_output = described_class.new(Wiki.first).get_revision_data rev_ids
    digger = ['enwiki', 'scores', '641962088', 'articlequality',
              'features', 'feature.english.stemmed.revision.stems_length']
    first_rev_ores = ores_output.dig(*digger)
    first_rev_liftwing = lift_wing_output.dig(*digger)
    expect(first_rev_ores).to eq(first_rev_liftwing)
  end

  it 'handles TextDeleted revs similarly', vcr: true do
    ores_output = OresApi.new(Wiki.first).get_revision_data [708326238]
    lift_wing_output = described_class.new(Wiki.first).get_revision_data [708326238]
    # It doesn't need to have the exact same response,
    # but it does need the error type in the same place.
    digger = %w[enwiki scores 708326238 articlequality error type]
    expect(ores_output.dig(*digger)).to eq(lift_wing_output.dig(*digger))
  end
end
