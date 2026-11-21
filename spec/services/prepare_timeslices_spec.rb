# frozen_string_literal: true

require 'rails_helper'

describe PrepareTimeslices do
  let(:course) { create(:basic_course, start: '2021-01-24 05:00:00', end: '2021-01-30 05:00:00') }

  describe '#adjust_timeslices' do
    let(:subject) { described_class.new(course, UpdateDebugger.new(course)) }

    it 'creates timeslices during the first update' do
      expect(course.course_wiki_timeslices.count).to eq(0)
      subject.adjust_timeslices

      expect(course.course_wiki_timeslices.count).to eq(7)
    end

    it 'works if start and end datetimes change to future time' do
      subject.adjust_timeslices
      expect(course.course_wiki_timeslices.count).to eq(7)
      first_timeslice = course.course_wiki_timeslices.first
      last_timeslice = course.course_wiki_timeslices.last

      course.update(start: '2021-01-24 17:00:00')
      course.update(end: '2021-01-30 17:00:00')
      subject.adjust_timeslices

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.first).to eq(first_timeslice)
      expect(course.course_wiki_timeslices.last).to eq(last_timeslice)
    end

    it 'works if start and end datetimes change to previous time' do
      subject.adjust_timeslices
      expect(course.course_wiki_timeslices.count).to eq(7)

      course.update(start: '2021-01-23 22:00:00')
      course.update(end: '2021-01-29 22:00:00')
      subject.adjust_timeslices

      expect(course.course_wiki_timeslices.count).to eq(7)
      expect(course.course_wiki_timeslices.minimum(:start)).to eq('2021-01-23 05:00:00')
      expect(course.course_wiki_timeslices.maximum(:end)).to eq('2021-01-30 05:00:00')
    end

    # New students are processed up to the timeslice for the latest date to update
    # (today, or the course start/end), so that timeslice must exist for the new dates.
    context 'when a student joins in the same update as a date change' do
      let(:user) { create(:user) }
      let(:fetched_starts) { [] }

      before do
        course.flags = { use_acuwt: true,
                         'update_logs' => { 1 => { 'start_time' => 3.minutes.ago,
                                                   'end_time' => 2.minutes.ago } } }
        course.save
        allow_any_instance_of(CourseRevisionUpdater)
          .to receive(:fetch_revisions_for_new_users) do |_updater, _wiki, _users, ts_start, _|
          fetched_starts << ts_start
          []
        end
        subject.adjust_timeslices
        CoursesUsers.create(course:, user:, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      context 'when the end date is extended past today' do
        around { |example| travel_to(Time.zone.parse('2021-02-02 12:00:00')) { example.run } }

        it 'processes the new student up to today' do
          course.update(end: '2021-02-05 05:00:00')
          expect(Sentry).not_to receive(:capture_exception)
          subject.adjust_timeslices
          expect(fetched_starts.max).to eq(Time.zone.parse('2021-02-02 05:00:00'))
        end
      end

      context 'when the start date is moved earlier and the course has not started' do
        around { |example| travel_to(Time.zone.parse('2021-01-20 12:00:00')) { example.run } }

        it 'processes the new student up to the new start date' do
          course.update(start: '2021-01-22 05:00:00')
          expect(Sentry).not_to receive(:capture_exception)
          subject.adjust_timeslices
          expect(fetched_starts.max).to eq(Time.zone.parse('2021-01-22 05:00:00'))
        end
      end

      context 'when the dates change drastically' do
        around { |example| travel_to(Time.zone.parse('2021-02-12 12:00:00')) { example.run } }

        it 'processes the new student only in the new period, up to today' do
          course.update(start: '2021-02-10 05:00:00', end: '2021-02-16 05:00:00')
          expect(Sentry).not_to receive(:capture_exception)
          subject.adjust_timeslices
          expect(fetched_starts.min).to eq(Time.zone.parse('2021-02-10 05:00:00'))
          expect(fetched_starts.max).to eq(Time.zone.parse('2021-02-12 05:00:00'))
        end
      end
    end
  end
end
