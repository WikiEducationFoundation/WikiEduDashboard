# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_wikidata_editors_csv_builder"

describe CourseWikidataEditorsCsvBuilder do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:course) { create(:course, home_wiki: wikidata) }
  let(:user) { create(:user, username: 'Testuser') }
  let(:builder) { described_class.new(course) }

  before do
    stub_wiki_validation
    create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  it 'generates headers starting with username' do
    csv = builder.generate_csv
    expect(csv.lines.first).to start_with('username,')
  end

  it 'generates one row per student' do
    csv = builder.generate_csv
    expect(csv.lines.count).to eq(2)
  end

  it 'includes the username in the row' do
    csv = builder.generate_csv
    expect(csv.lines.last).to start_with('Testuser,')
  end

  context 'when user has wikidata timeslice stats' do
    before do
      create(:course_user_wiki_timeslice,
             course:,
             user:,
             wiki: wikidata,
             stats: { 'items created' => 3, 'claims created' => 7 })
    end

    it 'includes summed stats in the row' do
      csv = builder.generate_csv
      row = CSV.parse(csv).last
      items_col = described_class::CSV_HEADERS.index('items created')
      claims_col = described_class::CSV_HEADERS.index('claims created')
      expect(row[items_col]).to eq('3')
      expect(row[claims_col]).to eq('7')
    end

    it 'sums stats across multiple timeslices' do
      create(:course_user_wiki_timeslice,
             course:,
             user:,
             wiki: wikidata,
             stats: { 'items created' => 2, 'claims created' => 1 })
      csv = builder.generate_csv
      row = CSV.parse(csv).last
      items_col = described_class::CSV_HEADERS.index('items created')
      expect(row[items_col]).to eq('5')
    end
  end
end
