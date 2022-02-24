# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/analytics/course_wikidata_csv_builder.rb"

describe CourseWikidataCsvBuilder do
  let(:course) { create(:course) }
  let(:another_course) { create(:course, slug: 'myschool/mycourse') }
  let(:builder) { described_class.new(course) }
  let(:campaign_builder) { described_class.new(ActiveRecord::Relation.new(Course)) }
  let(:create_course_stat) do
    create(:course_stats,
           stats_hash: { 'www.wikidata.org' => { 'claims created' => 2 } }, course_id: course.id)
  end
  let(:create_another_course_stat) do
    create(:course_stats,
           stats_hash: { 'www.wikidata.org' => { 'claims created' => 9 } },
           course_id: another_course.id)
  end

  context 'when no course_stat' do
    it 'generates only headers' do
      expect(builder.generate_csv).to eq "revision_type,count\ntotal revisions,0\n"
    end
  end

  context 'when course_stat exists' do
    before do
      create_course_stat
    end

    it 'generates csv data' do
      expect(builder.generate_csv).to eq "revision_type,count\nclaims created,2\n"
    end
  end

  # generate_csv also used in campaign context
  # see controller campaign and CSV actions
  # see also campaigns_controller_spec
  context 'when multiple courses in a campaign' do
    before do
      create_course_stat
      create_another_course_stat
    end

    # Since 2 + 9 = 11
    it 'generates csv of aggregated data' do
      expect(campaign_builder.generate_csv).to eq "revision_type,count\nclaims created,11\n"
    end
  end
end
