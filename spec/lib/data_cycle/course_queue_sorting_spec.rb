# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/data_cycle/course_queue_sorting"

describe CourseQueueSorting do
  let(:including_class) { Class.new { include CourseQueueSorting } }
  let(:subject) { including_class.new }

  let(:fast_finished_log) do
    { 1 => { 'start_time' => 10.seconds.ago, 'end_time' => 5.seconds.ago } }
  end

  describe '#queue_for' do
    context 'when there are 2 or more consecutive unfinished updates' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        flags: {
                          'update_logs' => fast_finished_log,
                          'unfinished_update_logs' => {
                            1 => { 'start_time' => 4.seconds.ago },
                            2 => { 'start_time' => 3.seconds.ago }
                          }
                        })
      end

      it 'queues in long_update' do
        expect(subject.queue_for(course)).to eq 'long_update'
      end
    end

    context 'when there is only 1 consecutive unfinished update' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        flags: {
                          'update_logs' => fast_finished_log,
                          'unfinished_update_logs' => {
                            1 => { 'start_time' => 4.seconds.ago }
                          }
                        })
      end

      it 'queues according to the last successful update time' do
        expect(subject.queue_for(course)).to eq 'short_update'
      end
    end

    context 'when there are old unfinished entries that predate the last success' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        flags: {
                          'update_logs' => fast_finished_log,
                          'unfinished_update_logs' => {
                            1 => { 'start_time' => 2.hours.ago },
                            2 => { 'start_time' => 1.hour.ago }
                          }
                        })
      end

      it 'ignores old entries and queues according to the last successful update time' do
        expect(subject.queue_for(course)).to eq 'short_update'
      end
    end
  end

  describe '#consecutive_unfinished_updates' do
    context 'when there are no unfinished logs' do
      let(:course) { create(:course, start: 1.day.ago, end: 2.months.from_now) }

      it 'returns 0' do
        expect(subject.consecutive_unfinished_updates(course)).to eq 0
      end
    end

    context 'when all unfinished logs are newer than the last successful end_time' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        flags: {
                          'update_logs' => fast_finished_log,
                          'unfinished_update_logs' => {
                            1 => { 'start_time' => 4.seconds.ago },
                            2 => { 'start_time' => 3.seconds.ago }
                          }
                        })
      end

      it 'counts all of them' do
        expect(subject.consecutive_unfinished_updates(course)).to eq 2
      end
    end

    context 'when unfinished logs predate the last successful end_time' do
      let(:course) do
        create(:course, start: 1.day.ago, end: 2.months.from_now,
                        flags: {
                          'update_logs' => fast_finished_log,
                          'unfinished_update_logs' => {
                            1 => { 'start_time' => 2.hours.ago },
                            2 => { 'start_time' => 1.hour.ago }
                          }
                        })
      end

      it 'returns 0' do
        expect(subject.consecutive_unfinished_updates(course)).to eq 0
      end
    end
  end
end
