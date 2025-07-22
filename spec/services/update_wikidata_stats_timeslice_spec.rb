# frozen_string_literal: true

require 'rails_helper'

describe UpdateWikidataStatsTimeslice do
  describe 'update_wikidata_statistics' do
    let(:wikidata) { Wiki.get_or_create(language: nil, project: 'wikidata') }
    let(:course) do
      create(:course, start: Date.new(2022, 1, 5), end: Date.new(2022, 1, 7),
                      home_wiki: wikidata)
    end
    let(:revision1) do
      build(:revision_on_memory, wiki_id: wikidata.id, mw_rev_id: 1556860240, scoped: true)
    end
    let(:revision2) do
      build(:revision_on_memory, wiki_id: wikidata.id, mw_rev_id: 99682035, scoped: true)
    end
    let(:unscoped_revision) do
      build(:revision_on_memory, wiki_id: wikidata.id, mw_rev_id: 99682036)
    end
    let(:revisions) { [revision1, revision2, unscoped_revision] }
    let(:updater) { described_class.new(course) }

    before do
      stub_wiki_validation
    end

    it 'imports wikidata', :vcr do
      revisions.each do |rev|
        expect(rev.summary).to be_nil
      end
      updater.update_revisions_with_stats(revisions)
      expect(revision1.summary).not_to be_nil
      expect(revision1.summary).not_to eq('null')
      expect(revision2.summary).not_to be_nil
      expect(revision2.summary).not_to eq('null')
      expect(unscoped_revision.summary).to be_nil
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

    context 'request fails' do
      it 'retries 3 times', :vcr do
        call_count = 0
        allow(WikidataDiffAnalyzer).to receive(:analyze)
          .and_wrap_original do |original_method, *args, &block|
          if call_count < 2
            call_count += 1
            raise MediawikiApi::HttpError
          else
            original_method.call(*args, &block)
          end
        end

        updater.update_revisions_with_stats(revisions)
        expect(revision1.summary).not_to be_nil
        expect(revision1.summary).not_to eq('null')
        expect(revision2.summary).not_to be_nil
        expect(revision2.summary).not_to eq('null')
      end

      it 'logs error once and marks revisions with error if request fails 3 times' do
        allow(WikidataDiffAnalyzer).to receive(:analyze)
          .and_raise(MediawikiApi::HttpError, '')
        expect(updater).to receive(:log_error).once
        updater.update_revisions_with_stats(revisions)
        expect(revision1.summary).to be_nil
        expect(revision1.error).to eq(true)
        expect(revision2.summary).to be_nil
        expect(revision2.error).to eq(true)
        expect(unscoped_revision.summary).to be_nil
        expect(unscoped_revision.error).to be_nil
      end
    end
  end
end
