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
      course.reload
    end

    it 'deletes wiki timeslices for the entire course properly' do
      expect(course.course_wiki_timeslices.size).to eq(333)
      expect(course.course_user_wiki_timeslices.size).to eq(3)
      expect(course.article_course_timeslices.size).to eq(3)

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
      create(:courses_wikis, wiki: wikibooks, course:)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikibooks,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
    end

    it 'deletes course user wiki timeslices for dates after the end date properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(3)

      date = '2024-04-11'.to_datetime - 1.second
      timeslice_cleaner.delete_course_user_wiki_timeslices_after_date([enwiki], date)
      course.reload

      # Course user wiki timeslices prior to the new start date were deleted
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

      # Course user wiki timeslices prior to the new start date were deleted
      expect(course.article_course_timeslices.size).to eq(2)
    end
  end

  describe '#reset_timeslices_that_need_update_from_article_timeslices' do
    let(:timeslices) { [] }

    before do
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikidata,
                                                                       enwiki])
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: enwiki,
              start: '2024-04-10'.to_datetime, end: '2024-04-11'.to_datetime)
      create(:course_user_wiki_timeslice, course:, user_id: 1, wiki: wikidata,
              start: '2024-04-11'.to_datetime, end: '2024-04-12'.to_datetime)
      timeslices << create(:article_course_timeslice, course:, article: article1,
             start: '2024-01-08'.to_datetime, end: '2024-01-09'.to_datetime)
      timeslices << create(:article_course_timeslice, course:, article: article1,
             start: '2024-04-10'.to_datetime, end: '2024-04-11'.to_datetime)
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
end
