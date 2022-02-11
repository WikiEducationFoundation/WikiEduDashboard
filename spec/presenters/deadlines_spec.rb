# frozen_string_literal: true

require 'rails_helper'
require_relative '../../app/presenters/deadlines'

describe Deadlines do
  describe '.course_creation_notice' do
    context 'when there is no deadline' do
      it 'returns nil' do
        expect(described_class.course_creation_notice).to be_nil
      end
    end

    context 'when there is a deadline' do
      before do
        described_class.update_student_program(
          recruiting_term: 'fall_2021',
          deadline: 1.week.from_now.to_date,
          before_deadline_message: 'You have one week left.',
          after_deadline_message: 'The deadline is passed.'
        )
      end

      it 'returns the "before" message before the deadline' do
        expect(described_class.course_creation_notice).to eq('You have one week left.')
      end

      it 'returns the "after" message after the deadline' do
        travel 2.weeks do
          expect(described_class.course_creation_notice).to eq('The deadline is passed.')
        end
      end
    end
  end

  describe '.recruiting_term' do
    context 'when there is a deadline' do
      before do
        described_class.update_student_program(
          recruiting_term: 'fall_2021',
          deadline: 1.week.from_now.to_date,
          before_deadline_message: 'You have one week left.',
          after_deadline_message: 'The deadline is passed.'
        )
      end

      it 'returns the student program recruiting term' do
        expect(described_class.recruiting_term).to eq('fall_2021')
      end
    end
  end
end
