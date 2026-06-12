# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe ReprocessArticleCourseUserWikiTimeslices do
  let(:ts_start) { '2021-01-24'.to_datetime }
  let(:ts_end) { ts_start + 1.day }
  let(:enwiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, title: 'ACUWT course', school: 'WÏNTR', term: 'spring 2021',
           slug: 'WÏNTR/ACUWT_course_(spring_2021)', start: ts_start, end: '2021-01-30',
           flags: { use_acuwt: true })
  end
  let(:user1) { create(:user, username: 'User1') }
  let(:user2) { create(:user, username: 'User2') }
  let(:article1) { create(:article, wiki: enwiki) }
  let(:article2) { create(:article, title: 'SecondArticle', wiki: enwiki) }

  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
    TimesliceManager.new(course).create_timeslices_for_new_course_wiki_records([enwiki])
  end

  describe '#run' do
    context 'when no ACUWT rows have needs_update: true' do
      before do
        create(:article_course_user_wiki_timeslice,
               course:, article: article1, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end, needs_update: false)
      end

      it 'does nothing' do
        expect_any_instance_of(RevisionDataManager)
          .not_to receive(:fetch_revision_data_for_users_with_articles_only)
        described_class.new(course, enwiki).run
        expect(course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(0)
      end
    end

    context 'when some ACUWT rows have needs_update: true' do
      before do
        create(:article_course_user_wiki_timeslice,
               course:, article: article1, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end, needs_update: true)
        create(:article_course_timeslice, course:, article: article1, start: ts_start)
        create(:course_user_wiki_timeslice, course:, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end)
        course.course_wiki_timeslices.where(start: ts_start).update_all(needs_update: true)
      end

      it 'marks CWT for reaggregation, clears needs_update, and removes ACT/CUWT rows' do
        revision = build(:revision_on_memory,
                         article_id: article1.id, user_id: user1.id, wiki_id: enwiki.id,
                         mw_rev_id: 12345, date: ts_start + 1.hour, error: false)
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_revision_data_for_users_with_articles_only).and_return([revision])
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_score_data_for_course).and_return([revision])

        described_class.new(course, enwiki).run

        cwt = course.course_wiki_timeslices.where(start: ts_start).first
        expect(cwt.needs_reaggregation).to eq(true)
        expect(cwt.needs_update).to eq(false)
        expect(course.article_course_timeslices.where(article: article1, start: ts_start).count)
          .to eq(0)
        expect(CourseUserWikiTimeslice.where(course:, start: ts_start).count).to eq(0)
      end

      it 'filters to failing articles before calling the score API' do
        create(:article_course_user_wiki_timeslice,
               course:, article: article2, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end, needs_update: false)

        failing_revision = build(:revision_on_memory,
                                 article_id: article1.id, user_id: user1.id, wiki_id: enwiki.id,
                                 mw_rev_id: 12345, date: ts_start + 1.hour)
        other_revision = build(:revision_on_memory,
                               article_id: article2.id, user_id: user1.id, wiki_id: enwiki.id,
                               mw_rev_id: 99999, date: ts_start + 2.hours)
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_revision_data_for_users_with_articles_only)
          .and_return([failing_revision, other_revision])
        expect_any_instance_of(RevisionDataManager)
          .to receive(:fetch_score_data_for_course)
          .with([failing_revision])
          .and_return([failing_revision])

        described_class.new(course, enwiki).run
      end
    end

    context 'when no revisions are returned for the failing period' do
      before do
        create(:article_course_user_wiki_timeslice,
               course:, article: article1, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end, needs_update: true)
        create(:article_course_timeslice, course:, article: article1, start: ts_start)
        course.course_wiki_timeslices.where(start: ts_start).update_all(needs_update: true)
      end

      it 'still marks CWT for reaggregation and clears needs_update' do
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_revision_data_for_users_with_articles_only).and_return([])

        described_class.new(course, enwiki).run

        cwt = course.course_wiki_timeslices.where(start: ts_start).first
        expect(cwt.needs_reaggregation).to eq(true)
        expect(cwt.needs_update).to eq(false)
        expect(course.article_course_timeslices.where(article: article1, start: ts_start).count)
          .to eq(0)
      end
    end

    context 'when failing ACUWT rows span multiple periods' do
      let(:ts_start2) { ts_start + 1.day }
      let(:ts_end2) { ts_start2 + 1.day }

      before do
        create(:article_course_user_wiki_timeslice,
               course:, article: article1, user: user1, wiki: enwiki,
               start: ts_start, end: ts_end, needs_update: true)
        create(:article_course_user_wiki_timeslice,
               course:, article: article2, user: user2, wiki: enwiki,
               start: ts_start2, end: ts_end2, needs_update: true)
        create(:article_course_timeslice, course:, article: article1, start: ts_start)
        create(:article_course_timeslice, course:, article: article2, start: ts_start2)
        course.course_wiki_timeslices
              .where(start: [ts_start, ts_start2])
              .update_all(needs_update: true)
      end

      it 'processes each period independently' do
        revision1 = build(:revision_on_memory,
                          article_id: article1.id, user_id: user1.id,
                          wiki_id: enwiki.id, mw_rev_id: 11111, date: ts_start + 1.hour)
        revision2 = build(:revision_on_memory,
                          article_id: article2.id, user_id: user2.id,
                          wiki_id: enwiki.id, mw_rev_id: 22222, date: ts_start2 + 1.hour)
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_revision_data_for_users_with_articles_only)
          .and_return([revision1], [revision2])
        allow_any_instance_of(RevisionDataManager)
          .to receive(:fetch_score_data_for_course)
          .and_return([revision1], [revision2])

        described_class.new(course, enwiki).run

        expect(course.course_wiki_timeslices.where(needs_reaggregation: true).count).to eq(2)
        expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(0)
        expect(course.article_course_timeslices.count).to eq(0)
      end
    end
  end
end
