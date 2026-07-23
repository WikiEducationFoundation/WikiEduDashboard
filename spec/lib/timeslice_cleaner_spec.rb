# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_cleaner"
require "#{Rails.root}/lib/timeslice_manager"

describe TimesliceCleaner do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:wikibooks) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:course) { create(:course, start: '2024-01-01', end: '2024-04-20') }
  let(:enwiki_course) { CoursesWikis.find_or_create_by(course:, wiki: enwiki) }
  let(:wikidata_course) { CoursesWikis.find_or_create_by(course:, wiki: wikidata) }
  let(:timeslice_cleaner) { described_class.new(course) }
  let(:timeslice_manager) { TimesliceManager.new(course) }
  let(:article1) { create(:article, wiki_id: enwiki.id) }
  let(:article2) { create(:article, wiki_id: wikidata.id) }
  let(:article3) { create(:article, wiki_id: wikidata.id) }

  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
    travel_to Date.new(2024, 1, 21)
    enwiki_course
    wikidata_course

    create(:articles_course, article_id: article1.id, course:)
    create(:articles_course, article_id: article2.id, course:)
    create(:articles_course, article_id: article3.id, course:)

    course.reload
  end

  after do
    travel_back
  end

  describe '#delete_course_user_timeslices_for_deleted_course_users' do
    before do
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki)
      create(:course_user_wiki_timeslice, course:, user_id: 2, wiki: enwiki)
      create(:course_user_wiki_timeslice, course:, user_id: 3, wiki: enwiki)
    end

    it 'deletes course user wiki timeslices for the given users properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(3)

      timeslice_cleaner.delete_course_user_timeslices_for_deleted_course_users([1, 2])
      expect(course.course_user_wiki_timeslices.size).to eq(1)
    end
  end

  describe '#delete_timeslices_for_deleted_course_wikis' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikibooks)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki)
      create(:article_course_timeslice, course:, article: article1)
      create(:article_course_timeslice, course:, article: article2)
      create(:article_course_timeslice, course:, article: article3)
      create(:article_course_user_wiki_timeslice, course:, wiki: wikidata,
             article: article2, user_id: 1)
      create(:article_course_user_wiki_timeslice, course:, wiki: enwiki,
             article: article1, user_id: 1)
      course.reload
    end

    it 'deletes wiki timeslices for the entire course properly' do
      expect(course.course_wiki_timeslices.size).to eq(333)
      expect(course.course_user_wiki_timeslices.size).to eq(3)
      expect(course.article_course_timeslices.size).to eq(3)
      expect(ArticleCourseUserWikiTimeslice.where(course:).count).to eq(2)

      timeslice_cleaner.delete_timeslices_for_deleted_course_wikis([wikibooks.id,
                                                                    wikidata.id])
      course.reload
      expect(course.course_user_wiki_timeslices.size).to eq(1)
      # Course wiki timeslices for wikibooks and wikidata were deleted
      expect(course.course_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
      expect(course.course_wiki_timeslices.where(wiki_id: wikidata.id).size).to eq(0)
      # Course user wiki timeslices for wikibooks and wikidata were deleted
      expect(course.course_user_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
      expect(course.course_user_wiki_timeslices.where(wiki_id: wikidata.id).size).to eq(0)
      # Article course timeslices for wikibooks and wikidata were deleted
      expect(course.article_course_timeslices.size).to eq(1)
      # Article course user wiki timeslices for wikidata were deleted; enwiki remains
      expect(ArticleCourseUserWikiTimeslice.where(course:, wiki: wikidata).count).to eq(0)
      expect(ArticleCourseUserWikiTimeslice.where(course:, wiki: enwiki).count).to eq(1)
    end
  end

  describe '#delete_timeslices_for_period' do
    let(:start_date) { DateTime.new(2024, 3, 29) }
    let(:end_date) { DateTime.new(2024, 3, 30) }

    before do
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikidata,
                                                                       enwiki])
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata,
      start: start_date, end: end_date)
      create(:course_user_wiki_timeslice, course:, user_id: 2, wiki: wikidata,
      start: start_date, end: end_date)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
      start: start_date, end: end_date)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata,
      start: end_date, end: end_date + 1.day)
      create(:article_course_timeslice, course:, article: article1, start: start_date,
      end: end_date)
      create(:article_course_timeslice, course:, article: article2, start: start_date,
      end: end_date)
      create(:article_course_timeslice, course:, article: article3, start: end_date,
      end: end_date + 1.day)
      course.reload
    end

    it 'deletes course timeslices for the given period' do
      expect(course.course_wiki_timeslices.size).to eq(222)
      expect(course.course_user_wiki_timeslices.size).to eq(4)
      expect(course.article_course_timeslices.size).to eq(3)

      timeslice_cleaner.delete_timeslices_for_period([wikidata], start_date, end_date)
      course.reload

      expect(course.course_wiki_timeslices.size).to eq(221)
      expect(course.course_user_wiki_timeslices.size).to eq(2)
      expect(course.article_course_timeslices.size).to eq(2)
    end
  end

  describe '#delete_course_wiki_timeslices_prior_to_start_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      course.reload
    end

    it 'deletes course wiki timeslices for dates prior to start date properly' do
      expect(course.course_wiki_timeslices.size).to eq(333)

      # Update course start date
      course.update(start: '2024-01-10'.to_datetime)
      timeslice_cleaner.delete_course_wiki_timeslices_prior_to_start_date
      course.reload

      # Course wiki timeslices prior to the new start date were deleted
      expect(course.course_wiki_timeslices.size).to eq(306)
    end
  end

  describe '#delete_course_wiki_timeslices_after_end_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      course.reload
    end

    it 'deletes course wiki timeslices for dates after the end date properly' do
      expect(course.course_wiki_timeslices.size).to eq(333)

      # Update course start date
      course.update(end: '2024-04-10'.to_datetime)
      timeslice_cleaner.delete_course_wiki_timeslices_after_end_date
      course.reload

      # Course wiki timeslices prior to the new start date were deleted
      expect(course.course_wiki_timeslices.size).to eq(303)
    end
  end

  describe '#delete_course_user_wiki_timeslices_prior_to_start_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
             start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
             start: '2024-01-10'.to_datetime, end: '2024-01-11'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
             start: '2024-01-11'.to_datetime, end: '2024-01-12'.to_datetime)
      course.reload
    end

    it 'deletes course user wiki timeslices for dates prior to start date properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(3)

      # Update course start date
      course.update(start: '2024-01-10'.to_datetime)
      timeslice_cleaner.delete_course_user_wiki_timeslices_prior_to_start_date
      course.reload

      # Course user wiki timeslices prior to the new start date were deleted
      expect(course.course_user_wiki_timeslices.size).to eq(2)
    end
  end

  describe '#delete_course_user_wiki_timeslices_after_end_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-10'.to_datetime, end: '2024-04-11'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
    end

    it 'deletes course user wiki timeslices for dates after the end date properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(3)

      # Update course start date
      course.update(end: '2024-04-10'.to_datetime)
      timeslice_cleaner.delete_course_user_wiki_timeslices_after_end_date
      course.reload

      # Course user wiki timeslices prior to the new start date were deleted
      expect(course.course_user_wiki_timeslices.size).to eq(2)
    end
  end

  describe '#delete_course_wiki_timeslices_after_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      course.reload
    end

    it 'deletes course wiki timeslices after date properly' do
      expect(course.course_wiki_timeslices.size).to eq(333)

      timeslice_cleaner.delete_course_wiki_timeslices_after_date([wikidata, enwiki],
                                                                 '2024-04-01'.to_datetime)
      course.reload

      expect(course.course_wiki_timeslices.size).to eq(295)
    end
  end

  describe '#delete_course_user_wiki_timeslices_after_date' do
    before do
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
    end

    it 'deletes course user wiki timeslices for dates after the end date properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(3)

      date = '2024-04-11'.to_datetime - 1.second
      timeslice_cleaner.delete_course_user_wiki_timeslices_after_date([enwiki], date)
      course.reload

      expect(course.course_user_wiki_timeslices.size).to eq(2)
    end
  end

  describe '#delete_article_course_timeslices_after_date' do
    before do
      create(:article_course_timeslice, course:, article: article1,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:article_course_timeslice, course:, article: article1,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
      create(:article_course_timeslice, course:, article: article2,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
    end

    it 'deletes article course timeslices for dates after the end date properly' do
      expect(course.article_course_timeslices.size).to eq(3)

      date = '2024-04-11'.to_datetime - 1.second
      timeslice_cleaner.delete_article_course_timeslices_after_date([enwiki], date)
      course.reload

      expect(course.article_course_timeslices.size).to eq(2)
    end
  end

  describe '#reset_timeslices_that_need_update_from_article_timeslices' do
    let(:timeslice_ids) { [] }
    let(:timeslices) { ArticleCourseTimeslice.where(id: timeslice_ids) }

    before do
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikidata,
                                                                       enwiki])
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-10'.to_datetime, end: '2024-04-11'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
      timeslice_ids << create(:article_course_timeslice, course:, article: article1,
             start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime).id
      timeslice_ids << create(:article_course_timeslice, course:, article: article1,
             start: '2024-04-10'.to_datetime, end: '2024-04-11'.to_datetime).id
      create(:article_course_timeslice, course:, article: article3,
             start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
    end

    it 'resets timeslices softly properly for unknown wiki' do
      timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(timeslices,
                                                                                  soft: true)
      expect(course.article_course_timeslices.count).to eq(3)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'resets timeslices hardly properly for unknown wiki' do
      timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(timeslices)
      expect(course.article_course_timeslices.count).to eq(1)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'resets timeslices softly properly for known wiki' do
      timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(timeslices,
                                                                                  wiki: enwiki,
                                                                                  soft: true)
      expect(course.article_course_timeslices.count).to eq(3)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end

    it 'resets timeslices hardly properly for known wiki' do
      timeslice_cleaner.reset_timeslices_that_need_update_from_article_timeslices(timeslices,
                                                                                  wiki: enwiki)
      expect(course.article_course_timeslices.count).to eq(1)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(2)
      expect(course.course_user_wiki_timeslices.count).to eq(1)
    end
  end

  describe '#reset_timeslices_for_update_from_acuwt' do
    let(:other_article) { create(:article, wiki_id: enwiki.id) }
    let(:uncovered_article) { create(:article, wiki_id: enwiki.id) }
    let(:covered_start) { '2024-01-08'.to_datetime }
    let(:covered_end) { '2024-01-09'.to_datetime }
    let(:other_start) { '2024-01-15'.to_datetime }
    let(:other_end) { '2024-01-16'.to_datetime }
    # Passed records are article1's ACUWT rows, which define the covered period.
    let(:acuwt) { ArticleCourseUserWikiTimeslice.where(course:, article: article1) }

    before do
      timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])

      # article1's ACUWT row -> defines the covered (enwiki, covered_start) period
      create(:article_course_user_wiki_timeslice, course:, article: article1, user_id: 1,
             wiki: enwiki, start: covered_start, end: covered_end)
      # A different article/user in the SAME period -> deleted (whole-period ACUWT)
      create(:article_course_user_wiki_timeslice, course:, article: other_article, user_id: 2,
             wiki: enwiki, start: covered_start, end: covered_end)
      # ACUWT in an uncovered period -> kept
      create(:article_course_user_wiki_timeslice, course:, article: uncovered_article, user_id: 1,
             wiki: enwiki, start: other_start, end: other_end)

      # CUWT in the covered period -> deleted (whole-period); another period -> kept
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
             start: covered_start, end: covered_end)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
             start: other_start, end: other_end)

      # ACT for the passed article -> deleted; for another article -> kept (article-scoped)
      create(:article_course_timeslice, course:, article: article1,
             start: covered_start, end: covered_end)
      create(:article_course_timeslice, course:, article: other_article,
             start: covered_start, end: covered_end)
    end

    it 'marks only the covering CWTs as needs_update (not needs_reaggregation)' do
      timeslice_cleaner.reset_timeslices_for_update_from_acuwt(acuwt)

      covering = course.course_wiki_timeslices.find_by(wiki: enwiki, start: covered_start)
      expect(covering.needs_update).to eq(true)
      expect(covering.needs_reaggregation).to eq(false)
      expect(course.course_wiki_timeslices.where(needs_update: true).count).to eq(1)
    end

    it 'deletes every ACUWT row in the covered period but keeps other periods' do
      timeslice_cleaner.reset_timeslices_for_update_from_acuwt(acuwt)

      covered = ArticleCourseUserWikiTimeslice.where(course:, wiki: enwiki, start: covered_start)
      other = ArticleCourseUserWikiTimeslice.where(course:, wiki: enwiki, start: other_start)
      expect(covered.count).to eq(0)
      expect(other.count).to eq(1)
    end

    it 'deletes CUWT rows in the covered period but keeps other periods' do
      timeslice_cleaner.reset_timeslices_for_update_from_acuwt(acuwt)

      expect(course.course_user_wiki_timeslices.where(start: covered_start).count).to eq(0)
      expect(course.course_user_wiki_timeslices.where(start: other_start).count).to eq(1)
    end

    it 'deletes ACT only for the passed articles, leaving other articles in the period' do
      timeslice_cleaner.reset_timeslices_for_update_from_acuwt(acuwt)

      expect(course.article_course_timeslices.where(article: article1)).to be_empty
      expect(course.article_course_timeslices.where(article: other_article)).not_to be_empty
    end

    it 'does nothing when there are no ACUWT records' do
      timeslice_cleaner.reset_timeslices_for_update_from_acuwt(ArticleCourseUserWikiTimeslice.none)

      expect(course.course_wiki_timeslices.where(needs_update: true)).to be_empty
    end
  end
end
