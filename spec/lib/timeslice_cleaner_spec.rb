# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_cleaner"

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
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
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
end
