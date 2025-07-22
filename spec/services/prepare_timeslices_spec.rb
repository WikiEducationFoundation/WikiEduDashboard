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
  end
end
