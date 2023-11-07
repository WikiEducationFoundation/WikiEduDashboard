# frozen_string_literal: true

require 'rails_helper'

require Rails.root.join('lib/importers/revision_importer')
require Rails.root.join('app/services/update_wikidata_stats')

describe UpdateWikidataStats do
  describe 'import_summaries' do
    let(:user) { create(:user, username: 'M2k~dewiki') }
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) do
      create(:course, start: Date.new(2022, 1, 5), end: Date.new(2022, 1, 7),
                      home_wiki: wikidata)
    end

    before do
      stub_wiki_validation
      item = create(:article, mw_page_id: 15101047, wiki: wikidata)
      create(:courses_user, course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      create(:revision, id: 653145, article: item, wiki: wikidata, user:,
        date: Time.zone.local(2022, 0o1, 0o6, 0, 0, 0o1), deleted: false, mw_rev_id: 1556860240,
        mw_page_id: 15101047, summary: nil)
      described_class.new(course)
    end

    it 'imports summaries', :vcr do
      expect(Revision.last.summary).not_to be_nil
    end

    it 'creates record in CourseStat table', :vcr do
      expect(CourseStat.count).to eq(1)
      expect(CourseStat.last.stats_hash).not_to be_nil
      expect(CourseStat.last.course_id).to eq(Course.last.id)
    end
  end
end
