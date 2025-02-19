# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/revision_stat_timeslice"

describe RevisionStatTimeslice do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:wikidata) { Wiki.get_or_create(project: 'wikidata', language: nil) }
  let(:daily_timeslice) { 1.day }
  let(:ten_timeslice) { 10.days }
  let!(:course) { create(:course, start: 2.months.ago, end: 2.days.from_now) }

  let(:date) { 7.days.ago.to_date }

  describe '#recent_revisions_for_course' do
    subject { described_class.new(course).recent_revisions_for_course }

    before do
      travel_to Time.zone.today
      stub_wiki_validation
      course.wikis << wikidata
    end

    context 'when daily timeslices' do
      before do
        start_timeframe = 7.days.ago.to_date

        # Create first course wiki timeslice for wikis
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)
        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)

        # Create extra timeslices
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_date,
         end: start_date + daily_timeslice, revision_count: 13)

        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_date,
       end: start_date + daily_timeslice, revision_count: 5)
        create(:course_wiki_timeslice, course:, wiki: wikidata,
          start: start_date - daily_timeslice, end: start_date, revision_count: 1)
      end

      context 'when no revisions' do
        let(:start_date) { 1.month.ago.to_date }

        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'when revisions in timeframe' do
        let(:start_date) { 2.days.ago.to_date }

        it 'does include in scope' do
          expect(subject).to eq(19)
        end
      end
    end

    context 'when 10-days timeslices' do
      before do
        start_timeframe = 12.days.ago.to_date

        # Create first course wiki timeslice for wikis
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)
        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)

        # Create extra timeslices
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_date,
         end: start_date + ten_timeslice, revision_count: 13)

        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_date,
       end: start_date + ten_timeslice, revision_count: 5)
      end

      context 'when no revisions' do
        let(:start_date) { 1.month.ago.to_date }

        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'when revisions in timeframe' do
        let(:start_date) { 2.days.ago.to_date }

        it 'does include in scope' do
          expect(subject).to eq(11)
        end
      end
    end
  end

  describe '#recent_revisions_for_courses_user' do
    subject { described_class.new(course).recent_revisions_for_courses_user(courses_user) }

    let(:user) { create(:user) }
    let(:courses_user) { create(:courses_user, course_id: course.id, user_id: user.id) }

    let(:user2) { create(:user, username: 'username') }

    before do
      travel_to Time.zone.today
      stub_wiki_validation
      course.wikis << wikidata
    end

    context 'when daily timeslices' do
      before do
        start_timeframe = 7.days.ago.to_date

        # Create first course wiki timeslice for wikis
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)
        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)

        create(:course_user_wiki_timeslice, course:, user:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)
        create(:course_user_wiki_timeslice, course:, user:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + daily_timeslice, revision_count: 0)

        # Create extra timeslices
        create(:course_user_wiki_timeslice, course:, user:, wiki: enwiki, start: start_date,
         end: start_date + daily_timeslice, revision_count: 13)
        create(:course_user_wiki_timeslice, course:, user:, wiki: wikidata, start: start_date,
       end: start_date + daily_timeslice, revision_count: 5)
        create(:course_user_wiki_timeslice, course:, user:, wiki: wikidata,
          start: start_date - daily_timeslice, end: start_date, revision_count: 1)

        # Create timeslices for another user
        create(:course_user_wiki_timeslice, course:, user: user2, wiki: enwiki, start: start_date,
        end: start_date + daily_timeslice, revision_count: 13)
      end

      context 'when no revisions' do
        let(:start_date) { 1.month.ago.to_date }

        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'when revisions in timeframe' do
        let(:start_date) { 2.days.ago.to_date }

        it 'does include in scope' do
          expect(subject).to eq(19)
        end
      end
    end

    context 'when 10-days timeslices' do
      before do
        start_timeframe = 12.days.ago.to_date

        # Create first course wiki timeslice for wikis
        create(:course_wiki_timeslice, course:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)
        create(:course_wiki_timeslice, course:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)
        create(:course_user_wiki_timeslice, course:, user:, wiki: enwiki, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)
        create(:course_user_wiki_timeslice, course:, user:, wiki: wikidata, start: start_timeframe,
          end: start_timeframe + ten_timeslice, revision_count: 0)

        # Create extra timeslices
        create(:course_user_wiki_timeslice, course:, user:, wiki: enwiki, start: start_date,
         end: start_date + ten_timeslice, revision_count: 13)
        create(:course_user_wiki_timeslice, course:, user:, wiki: wikidata, start: start_date,
       end: start_date + ten_timeslice, revision_count: 5)

        # Create timeslices for another user
        create(:course_user_wiki_timeslice, course:, user: user2, wiki: wikidata, start: start_date,
          end: start_date + ten_timeslice, revision_count: 5)
      end

      context 'when no revisions' do
        let(:start_date) { 1.month.ago.to_date }

        it 'does not include in scope' do
          expect(subject).to eq(0)
        end
      end

      context 'when revisions in timeframe' do
        let(:start_date) { 2.days.ago.to_date }

        it 'does include in scope' do
          expect(subject).to eq(11)
        end
      end
    end
  end
end
