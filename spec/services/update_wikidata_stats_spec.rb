# frozen_string_literal: true

require 'rails_helper'

require "#{Rails.root}/lib/importers/revision_importer"
require "#{Rails.root}/app/services/update_wikidata_stats"

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

    it 'should import summaries', :vcr do
      expect(Revision.last.summary).not_to be_nil
    end

    it 'should create record in CourseStat table', :vcr do
      expect(CourseStat.count).to eq(1)
      expect(CourseStat.last.stats_hash).not_to be_nil
      expect(CourseStat.last.course_id).to eq(Course.last.id)
    end

    it 'handles encoding problems gracefully', :vcr do
      allow_any_instance_of(Revision).to receive(:update!).and_raise(ActiveRecord::StatementInvalid)
      expect(Sentry).to receive(:capture_exception).at_least(:once)
      Revision.last.update(summary: nil)
      described_class.new(course)
    end
  end
end
