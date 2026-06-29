# frozen_string_literal: true

require 'rails_helper'

describe ScheduleCourseAdviceEmails do
  let(:course) do
    create(:course, timeline_start: '2016-01-01', timeline_end: '2016-03-01')
  end
  let(:choosing_block) { instance_double(Block, calculated_date: 1.week.from_now) }

  before do
    create(:tag, course:, tag: 'research_write_assignment', key: 'assignment_type')
    allow(course).to receive(:find_block_by_title).and_return(nil)
    allow(course).to receive(:find_block_by_title).with('Choose your article')
                                                  .and_return(choosing_block)
    allow(CourseAdviceEmailWorker).to receive(:schedule_email)
  end

  context 'when the instructor_learner tag is present' do
    before { create(:tag, course:, tag: 'instructor_learner', key: 'instructor_learner') }

    it 'schedules the learning_to_edit advice email' do
      described_class.new(course).schedule_emails
      expect(CourseAdviceEmailWorker).to have_received(:schedule_email)
        .with(hash_including(course:, subject: 'learning_to_edit'))
    end
  end

  context 'when the instructor_learner tag is absent' do
    it 'does not schedule the learning_to_edit advice email' do
      described_class.new(course).schedule_emails
      expect(CourseAdviceEmailWorker).not_to have_received(:schedule_email)
        .with(hash_including(subject: 'learning_to_edit'))
    end
  end
end
