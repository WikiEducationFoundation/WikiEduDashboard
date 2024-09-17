# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/timeslice_manager"

describe TimesliceManager do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:wikibooks) { Wiki.get_or_create(language: 'en', project: 'wikibooks') }
  let(:course) { create(:course, start: '2024-01-01', end: '2024-04-20') }
  let(:enwiki_course) { CoursesWikis.find_or_create_by(course:, wiki: enwiki) }
  let(:wikidata_course) { CoursesWikis.find_or_create_by(course:, wiki: wikidata) }
  let(:timeslice_manager) { described_class.new(course) }
  let(:article1) { create(:article, wiki_id: enwiki.id) }
  let(:article2) { create(:article, wiki_id: wikidata.id) }
  let(:article3) { create(:article, wiki_id: wikidata.id) }
  let(:new_article_courses) { [] }
  let(:new_course_users) { [] }
  let(:new_course_wikis) { [] }

  before do
    stub_wiki_validation
    travel_to Date.new(2024, 1, 21)
    enwiki_course
    wikidata_course

    new_course_users << create(:courses_user, id: 1, user_id: 1, course:,
                               role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    new_course_users << create(:courses_user, id: 2, user_id: 2, course:)
    new_course_users << create(:courses_user, id: 3, user_id: 3, course:)

    new_article_courses << create(:articles_course, article_id: article1.id, course:)
    new_article_courses << create(:articles_course, article_id: article2.id, course:)
    new_article_courses << create(:articles_course, article_id: article3.id, course:)
    course.reload
  end

  describe '#create_timeslices_for_new_article_course_records' do
    context 'when there are new articles courses' do
      it 'creates article course timeslices for the entire course' do
        expect(course.article_course_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_article_course_records(
          new_article_courses
        )
        course.reload
        expect(course.article_course_timeslices.size).to eq(342)
        expect(course.article_course_timeslices.min_by(&:start).start.to_date)
          .to eq(Date.new(2023, 12, 29))
        expect(course.article_course_timeslices.max_by(&:start).start.to_date)
          .to eq(Date.new(2024, 4, 20))
      end
    end
  end

  describe '#create_timeslices_for_new_course_user_records' do
    context 'when there are new courses users' do
      it 'creates course user wiki timeslices for every wiki for the entire course' do
        expect(course.course_user_wiki_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_course_user_records(
          new_course_users
        )
        course.reload
        expect(course.course_user_wiki_timeslices.size).to eq(684)
        expect(course.course_user_wiki_timeslices.min_by(&:start).start.to_date)
          .to eq(Date.new(2023, 12, 29))
        expect(course.course_user_wiki_timeslices.max_by(&:start).start.to_date)
          .to eq(Date.new(2024, 4, 20))
      end
    end
  end

  describe '#create_course_wiki_timeslices_for_new_records' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
    end

    context 'when there are new courses wikis' do
      it 'creates course wiki and course user wiki timeslices for the entire course' do
        # Course wiki timeslices already exist for home wiki
        expect(course.course_wiki_timeslices.size).to eq(114)
        expect(course.course_wiki_timeslices.first.wiki).to eq(enwiki)
        timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks])
        # Create wikibooks course wiki timeslices for the entire course
        expect(course.course_wiki_timeslices.last.wiki).to eq(wikibooks)
        expect(course.course_wiki_timeslices.size).to eq(228)
        # Create all the course user wiki timeslices for the existing course users with student role
        # for the new wiki
        expect(course.course_user_wiki_timeslices.first.wiki).to eq(wikibooks)
        expect(course.course_user_wiki_timeslices.size).to eq(228)
      end
    end
  end

  describe '#delete_course_user_timeslices_for_deleted_course_users' do
    before do
      timeslice_manager.create_timeslices_for_new_course_user_records(new_course_users)
    end

    it 'deletes course user wiki timeslices for the given users properly' do
      expect(course.course_user_wiki_timeslices.size).to eq(684)

      timeslice_manager.delete_course_user_timeslices_for_deleted_course_users([1, 2])
      expect(course.course_user_wiki_timeslices.size).to eq(228)
    end
  end

  describe '#delete_timeslices_for_deleted_course_wikis' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks,
                                                                       wikidata,
                                                                       enwiki])
      timeslice_manager.create_timeslices_for_new_article_course_records(
        new_article_courses
      )
    end

    it 'deletes wiki timeslices for the entire course properly' do
      expect(course.course_wiki_timeslices.size).to eq(342)
      expect(course.course_user_wiki_timeslices.size).to eq(684)
      expect(course.article_course_timeslices.size).to eq(342)

      timeslice_manager.delete_timeslices_for_deleted_course_wikis([wikibooks.id, wikidata.id])
      course.reload
      # Course wiki timeslices for wikibooks and wikidata were deleted
      expect(course.course_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
      expect(course.course_wiki_timeslices.where(wiki_id: wikidata.id).size).to eq(0)
      # Course user wiki timeslices for wikibooks and wikidata were deleted
      expect(course.course_user_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
      expect(course.course_user_wiki_timeslices.where(wiki_id: wikidata.id).size).to eq(0)
      # Article course timeslices for wikibooks and wikidata were deleted
      expect(course.article_course_timeslices.size).to eq(114)
    end
  end

  describe '#get_ingestion_start_time_for_wiki' do
    context 'when no course wiki timeslices' do
      it 'returns course start date' do
        # no course wiki timeslices for wikibooks
        expect(course.course_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
        expect(timeslice_manager.get_ingestion_start_time_for_wiki(wikibooks))
          .to eq('20240101000000')
      end
    end

    context 'when empty course wiki timeslices' do
      it 'returns course start date' do
        # only empty course wiki timeslices for enwiki
        expect(course.course_wiki_timeslices.where(wiki_id: enwiki.id).size).to eq(114)
        expect(timeslice_manager.get_ingestion_start_time_for_wiki(enwiki)).to eq('20240101000000')
      end
    end

    context 'when non-empty course wiki timeslices' do
      it 'returns start datetime for the max last_mw_rev_datetime' do
        # update last_mw_rev_datetime
        # Update last_mw_rev_datetime for the first course_wiki_timeslice
        first_timeslice = course.course_wiki_timeslices[3]
        first_timeslice.last_mw_rev_datetime = '20240101103407'.to_datetime
        first_timeslice.save

        # Update last_mw_rev_datetime for the second course_wiki_timeslice
        second_timeslice = course.course_wiki_timeslices[4]
        second_timeslice.last_mw_rev_datetime = '20240102002146'.to_datetime
        second_timeslice.save

        # Update last_mw_rev_datetime for the fourth course_wiki_timeslice
        fourth_timeslice = course.course_wiki_timeslices[6]
        fourth_timeslice.last_mw_rev_datetime = '20240104131500'.to_datetime
        fourth_timeslice.save

        expect(timeslice_manager.get_ingestion_start_time_for_wiki(enwiki)).to eq('20240104000000')
      end
    end
  end

  describe '#update_last_mw_rev_datetime' do
    let(:revision1) { create(:revision, date: '2024-01-01 15:45:53') }
    let(:revision2) { create(:revision, date: '2024-01-01 19:40:45') }
    let(:revision3) { create(:revision, date: '2024-01-01 13:40:45') }
    let(:revision4) { create(:revision, date: '2024-01-03 03:09:10') }
    let(:revisions) { [revision1, revision2, revision3, revision4] }
    let(:new_fetched_data) do
      { enwiki => { start: '20240101090035', end: '20240104101340', revisions: } }
    end

    context 'when there were updates' do
      it 'updates last_mw_rev_datetime for every course wiki' do
        course_wiki_timeslices = course.course_wiki_timeslices.where(wiki_id: enwiki.id)
        expect(course_wiki_timeslices.where(last_mw_rev_datetime: nil).size).to eq(114)
        timeslice_manager.update_last_mw_rev_datetime(new_fetched_data)
        # two course wiki timeslices were updated
        expect(course_wiki_timeslices.where(last_mw_rev_datetime: nil).size).to eq(112)
        # first, second and third timeslices are empty
        expect(course_wiki_timeslices.fourth.last_mw_rev_datetime).to eq('20240101194045')
        expect(course_wiki_timeslices[5].last_mw_rev_datetime).to eq('20240103030910')
      end
    end
  end
end
