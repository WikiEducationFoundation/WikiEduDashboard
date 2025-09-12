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
  let(:new_course_users) { [] }
  let(:today) { Date.new(2024, 1, 21) }

  before do
    stub_wiki_validation
    stub_const('TimesliceManager::TIMESLICE_DURATION', 86400)
    travel_to today
    enwiki_course
    wikidata_course

    new_course_users << create(:courses_user, id: 1, user_id: 1, course:,
                               role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    new_course_users << create(:courses_user, id: 2, user_id: 2, course:)
    new_course_users << create(:courses_user, id: 3, user_id: 3, course:)

    create(:articles_course, article_id: article1.id, course:)
    create(:articles_course, article_id: article2.id, course:)
    create(:articles_course, article_id: article3.id, course:)

    course.reload
  end

  after do
    travel_back
  end

  describe '#create_course_wiki_timeslices_for_new_records' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      course.reload
    end

    context 'when there are new courses wikis' do
      it 'creates course wiki timeslices for the entire course' do
        # No course wiki timeslices exist previously
        expect(course.course_wiki_timeslices.size).to eq(0)
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki,
                                                                         wikibooks])
        course.reload
        # Create enwiki and wikibooks course wiki timeslices for the entire course
        expect(course.course_wiki_timeslices.first.wiki).to eq(enwiki)
        expect(course.course_wiki_timeslices.last.wiki).to eq(wikibooks)
        expect(course.course_wiki_timeslices.size).to eq(222)

        expect(course.course_user_wiki_timeslices.size).to eq(0)
      end
    end
  end

  describe '#create_wiki_timeslices_for_new_course_start_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks])
      course.update(start: '2023-12-20')
      course.reload
    end

    context 'when the start date changed to a previous date' do
      it 'creates timeslices for the missing period that needs_update' do
        expect(course.course_wiki_timeslices.size).to eq(111)

        timeslice_manager.create_wiki_timeslices_for_new_course_start_date(wikibooks)
        course.reload
        # Create course timeslices for the period between 2023-12-20 and 2024-01-01
        expect(course.course_wiki_timeslices.size).to eq(123)
        expect(course.course_wiki_timeslices.where(needs_update: true).size).to eq(12)
      end
    end
  end

  describe '#create_wiki_timeslices_up_to_new_course_end_date' do
    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks])
      course.update(end: '2024-04-30')
      course.reload
    end

    context 'when the end date changed to a later date' do
      it 'creates timeslices for the missing period that needs_update' do
        expect(course.course_wiki_timeslices.size).to eq(111)

        timeslice_manager.create_wiki_timeslices_up_to_new_course_end_date(wikibooks)
        course.reload
        # Create course and user timeslices for the period between 2024-04-20 and 2024-04-30
        expect(course.course_wiki_timeslices.size).to eq(121)
        expect(course.course_wiki_timeslices.where(needs_update: true).size).to eq(10)
      end
    end
  end

  describe '#create_wiki_timeslices_for_period' do
    let(:start_period) { DateTime.new(2024, 3, 22) }
    let(:end_period) { DateTime.new(2024, 3, 23) }

    before do
      create(:courses_wikis, wiki: wikibooks, course:)
      timeslice_manager.create_timeslices_for_new_course_wiki_records([wikibooks])
      # Delete two timeslices
      CourseWikiTimeslice.where(course:, wiki: wikibooks, start: start_period,
                                end: end_period).delete_all
      CourseWikiTimeslice.where(course:, wiki: wikibooks, start: end_period,
                                end: end_period + 1.day).delete_all
    end

    it 'creates timeslices for the period' do
      expect(course.course_wiki_timeslices.size).to eq(109)

      timeslice_manager.create_wiki_timeslices_for_period(wikibooks, start_period, end_period)
      course.reload
      # Create two missing course wiki timeslice
      expect(course.course_wiki_timeslices.size).to eq(111)
      expect(course.course_wiki_timeslices.where(needs_update: true).size).to eq(2)
    end
  end

  describe '#maybe_create_course_wiki_timeslice' do
    let(:start_date) { DateTime.new(2024, 3, 22) }
    let(:end_date) { DateTime.new(2024, 3, 23) }

    it 'creates timeslice if it does not exist' do
      expect(course.course_wiki_timeslices.size).to eq(0)

      timeslice_manager.maybe_create_course_wiki_timeslice(wikibooks.id, start_date, end_date)
      course.reload
      expect(course.course_wiki_timeslices.size).to eq(1)
    end

    it 'does not fail if it already exists' do
      CourseWikiTimeslice.create(course:, wiki_id: wikibooks.id, start: start_date, end: end_date)
      expect(course.course_wiki_timeslices.size).to eq(1)

      timeslice_manager.maybe_create_course_wiki_timeslice(wikibooks.id, start_date, end_date)
      course.reload
      expect(course.course_wiki_timeslices.size).to eq(1)
    end
  end

  describe '#get_ingestion_start_time_for_wiki' do
    context 'when no course wiki timeslices' do
      it 'returns course start date' do
        # no course wiki timeslices for wikibooks
        expect(course.course_wiki_timeslices.where(wiki_id: wikibooks.id).size).to eq(0)
        expect(timeslice_manager.get_ingestion_start_time_for_wiki(wikibooks))
          .to eq('20240101000000'.to_datetime)
      end
    end

    context 'when empty course wiki timeslices' do
      it 'returns course start date' do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
        expect(course.course_wiki_timeslices.where(wiki_id: enwiki.id).size).to eq(111)
        expect(timeslice_manager.get_ingestion_start_time_for_wiki(enwiki))
          .to eq('20240101000000'.to_datetime)
      end
    end

    context 'when non-empty course wiki timeslices' do
      it 'returns start datetime for the max last_mw_rev_datetime' do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
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

        expect(timeslice_manager.get_ingestion_start_time_for_wiki(enwiki))
          .to eq('20240107000000'.to_datetime)
      end
    end
  end

  describe '#update_last_mw_rev_datetime' do
    context 'when there were updates' do
      let(:revision1) { build(:revision_on_memory, date: '2024-01-01 15:45:53') }
      let(:revision2) { build(:revision_on_memory, date: '2024-01-01 19:40:45') }
      let(:revision3) { build(:revision_on_memory, date: '2024-01-01 13:40:45') }
      let(:revision4) { build(:revision_on_memory, date: '2024-01-03 03:09:10') }
      let(:revisions) { [revision1, revision2, revision3, revision4] }
      let(:new_fetched_data) do
        { enwiki => { start: '20240101090035', end: '20240104101340', revisions: } }
      end

      it 'updates last_mw_rev_datetime for every course wiki' do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
        course_wiki_timeslices = course.course_wiki_timeslices.where(wiki_id: enwiki.id)
        expect(course_wiki_timeslices.where(last_mw_rev_datetime: nil).size).to eq(111)
        timeslice_manager.update_last_mw_rev_datetime(new_fetched_data)
        # two course wiki timeslices were updated
        expect(course_wiki_timeslices.where(last_mw_rev_datetime: nil).size).to eq(109)
        expect(course_wiki_timeslices.first.last_mw_rev_datetime).to eq('20240101194045')
        expect(course_wiki_timeslices.third.last_mw_rev_datetime).to eq('20240103030910')
      end
    end

    context 'when there are no revisions' do
      let(:new_fetched_data) do
        { enwiki => { start: '20240101', end: '20240102', revisions: [] } }
      end

      it 'cleans last_mw_rev_datetime' do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
        timeslice = course.course_wiki_timeslices.where(wiki_id: enwiki.id,
                                                        start: '2024-01-01').first
        timeslice.update(last_mw_rev_datetime: '2024-01-01 19:40:45')
        expect(course.course_wiki_timeslices.first.last_mw_rev_datetime).to eq('20240101194045')
        timeslice_manager.update_last_mw_rev_datetime(new_fetched_data)
        # last_mw_rev_datetime was set to nil
        expect(course.course_wiki_timeslices.first.last_mw_rev_datetime).to eq(nil)
      end
    end
  end

  describe '#get_latest_start_time_for_wiki' do
    let(:subject) { timeslice_manager.get_latest_start_time_for_wiki(enwiki) }

    context 'when course start and end dates are in the past' do
      before do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
        travel_to Date.new(2024, 6, 21)
      end

      after do
        travel_back
      end

      it 'returns end of course' do
        expect(subject).to eq(course.end.beginning_of_day)
      end
    end

    context 'when course start is past and course end is future' do
      before do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
      end

      after do
        travel_back
      end

      it 'returns today' do
        expect(subject).to eq(today)
      end
    end

    context 'when course start and end dates are future' do
      before do
        timeslice_manager.create_timeslices_for_new_course_wiki_records([enwiki])
        travel_to Date.new(2023, 6, 21)
      end

      after do
        travel_back
      end

      it 'returns course start date' do
        expect(subject).to eq(course.start)
      end
    end

    context 'when the timeslice does not exist' do
      it 'logs the error' do
        allow(Sentry).to receive(:capture_exception)
        expect(subject).to eq(nil)
        expect(Sentry).to have_received(:capture_exception)
      end
    end
  end
end
