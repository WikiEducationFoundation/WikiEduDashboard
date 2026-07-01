# frozen_string_literal: true

require 'rails_helper'

describe MarkPurgeableCourses do
  let(:enwiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }

  # Ended well over PURGEABLE_AFTER (6 months) ago, so it clears the date filter.
  let(:old_course) do
    create(:course, slug: 'School/Old_(Term)', start: 2.years.ago, end: 1.year.ago)
  end

  def add_timeslice(course, **attrs)
    create(:course_wiki_timeslice, course:, wiki: enwiki, **attrs)
  end

  describe '#marked_count' do
    it 'flags an old, tracked, idle course as purgeable' do
      add_timeslice(old_course)

      result = described_class.new

      expect(result.marked_count).to eq(1)
      expect(old_course.reload.purgeable?).to be true
    end

    it 'skips a course that ended within the purge window' do
      recent_course = create(:course, slug: 'School/Recent_(Term)',
                                      start: 2.months.ago, end: 1.month.ago)
      add_timeslice(recent_course)

      result = described_class.new

      expect(result.marked_count).to eq(0)
      expect(recent_course.reload.purgeable?).to be false
    end

    it 'skips a course never tracked in the timeslice system' do
      old_course # no course wiki timeslices created

      result = described_class.new

      expect(result.marked_count).to eq(0)
      expect(old_course.reload.purgeable?).to be false
    end

    it 'skips a course with a timeslice still needing update' do
      add_timeslice(old_course, needs_update: true)

      result = described_class.new

      expect(result.marked_count).to eq(0)
      expect(old_course.reload.purgeable?).to be false
    end

    it 'skips a course with a timeslice still needing reaggregation' do
      add_timeslice(old_course, needs_reaggregation: true)

      result = described_class.new

      expect(result.marked_count).to eq(0)
      expect(old_course.reload.purgeable?).to be false
    end

    it 'does not re-flag a course already marked purgeable' do
      add_timeslice(old_course)
      old_course.add_flag(key: :purgeable)

      result = described_class.new

      expect(result.marked_count).to eq(0)
    end

    it 'skips a course that may currently be running an update' do
      add_timeslice(old_course)
      old_course.add_flag(key: 'unfinished_update_logs',
                          value: { '1' => { 'start_time' => 1.day.ago.to_datetime } })

      result = described_class.new

      expect(result.marked_count).to eq(0)
      expect(old_course.reload.purgeable?).to be false
    end

    it 'flags a course whose only unfinished update log is stale' do
      add_timeslice(old_course)
      old_course.add_flag(key: 'unfinished_update_logs',
                          value: { '1' => { 'start_time' => 30.days.ago.to_datetime } })

      result = described_class.new

      expect(result.marked_count).to eq(1)
      expect(old_course.reload.purgeable?).to be true
    end

    it 'flags every eligible course' do
      add_timeslice(old_course)
      other = create(:course, slug: 'School/Other_(Term)', start: 2.years.ago, end: 1.year.ago)
      add_timeslice(other)

      result = described_class.new

      expect(result.marked_count).to eq(2)
      expect(old_course.reload.purgeable?).to be true
      expect(other.reload.purgeable?).to be true
    end
  end
end
