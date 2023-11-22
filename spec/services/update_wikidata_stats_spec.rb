# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/app/services/update_wikidata_stats"

describe UpdateWikidataStats do
  describe 'update_wikidata_statistics' do
    let(:user) { create(:user, username: 'M2k~dewiki') }
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) do
      create(:course, start: Date.new(2022, 1, 5), end: Date.new(2022, 1, 7),
                      home_wiki: wikidata)
    end

    before do
      stub_wiki_validation
      item = create(:article, mw_page_id: 702497, wiki: wikidata)
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:revision, article: item, wiki: wikidata, user:,
        date: Time.zone.local(2022, 0o1, 0o6, 0, 0, 0o1), deleted: false, mw_rev_id: 1556860240,
        mw_page_id: 15101047, summary: nil)
      # A legacy revision that has an imported edit summary
      create(:revision, wiki: wikidata, mw_rev_id: 996820366,
             summary: '%2F%2A+wbeditentity-override%3A0%7C+%2A%2F+Clearing')
      described_class.new(course)
    end

    it 'imports summaries', :vcr do
      Revision.all.each do |rev|
        expect(rev.summary).not_to be_nil
      end
    end

    it 'creates record in CourseStat table', :vcr do
      expect(CourseStat.count).to eq(1)
      expect(CourseStat.last.stats_hash).not_to be_nil
      expect(CourseStat.last.course_id).to eq(Course.last.id)
    end
  end
end
