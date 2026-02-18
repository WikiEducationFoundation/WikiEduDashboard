# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_csv_builder"
require "#{Rails.root}/lib/analytics/retained_new_editors_stats"

describe CourseCsvBuilder do
  let(:course) { create(:course) }
  let(:subject) { described_class.new(course).generate_csv }
  let(:manager) { instance_double(RetainedNewEditorsStats, count: 5) }

  before do
    # Mock the Stats class so we don't hit the API during CSV tests
    allow(RetainedNewEditorsStats).to receive(:new).with(course).and_return(manager)
  end

  it 'creates a CSV with a header and a row of data' do
    expect(subject.split("\n").count).to eq(2)
  end
  
  it 'includes the retained_new_editors count in the CSV' do
    rows = CSV.parse(subject)
    headers = rows[0]
    data = rows[1]

    retained_index = headers.index('retained_new_editors')
    expect(data[retained_index]).to eq("5")
  end
end
