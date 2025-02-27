# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/app/services/update_wikidata_stats"

describe UpdateWikidataStatsTimeslice do
  describe 'update_wikidata_statistics' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) do
      create(:course, start: Date.new(2022, 1, 5), end: Date.new(2022, 1, 7),
                      home_wiki: wikidata)
    end
    let(:revision1) { create(:revision, wiki: wikidata, mw_rev_id: 1556860240) }
    let(:revision2) { create(:revision, wiki: wikidata, mw_rev_id: 99682036) }
    let(:revisions) { [revision1, revision2] }
    let(:updater) { described_class.new(course) }

    before do
      stub_wiki_validation
    end

    it 'imports wikidata', :vcr do
      revisions.each do |rev|
        expect(rev.summary).to be_nil
      end
      updater.update_revisions_with_stats(revisions)
      revisions.each do |rev|
        expect(rev.summary).not_to be_nil
      end
    end

    it 'creates record in CourseStat table', :vcr do
      expect(CourseStat.count).to eq(0)
      updater.update_revisions_with_stats(revisions)
      partial_stats = updater.build_stats_from_revisions(revisions)
      updater.update_wikidata_statistics([partial_stats])
      expect(CourseStat.count).to eq(1)
      expect(CourseStat.last.stats_hash).not_to be_nil
      expect(CourseStat.last.course_id).to eq(Course.last.id)
    end
  end
end
