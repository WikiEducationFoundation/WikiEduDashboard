# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_csv_builder"

describe CourseCsvBuilder do
  let(:course) { create(:course) }
  let(:subject) { described_class.new(course).generate_csv }

  it 'creates a CSV with a header and a row of data' do
    expect(subject.split("\n").count).to eq(2)
  end
end
