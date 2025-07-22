# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_wikidata_csv_builder.rb"

describe CourseWikidataCsvBuilder do
  let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
  let(:course) { create(:course, home_wiki: wikidata) }
  let(:builder) { described_class.new(course) }
  let(:create_course_stat) do
    create(:course_stats,
           stats_hash: { 'www.wikidata.org' => { 'claims created' => 2 } }, course_id: course.id)
  end

  before { stub_wiki_validation }

  context 'when no course_stat' do
    it 'generates only headers' do
      expect(builder.generate_csv).to start_with('course name,')
      expect(builder.generate_csv.lines.count).to eq(1)
    end
  end

  context 'when course_stat exists' do
    before do
      create_course_stat
    end

    it 'generates csv data' do
      expect(builder.generate_csv.lines.first).to start_with('course name,claims created')
      expect(builder.generate_csv.lines.last).to start_with(course.title + ',2')
      expect(builder.generate_csv.lines.count).to eq 2
    end
  end
end
