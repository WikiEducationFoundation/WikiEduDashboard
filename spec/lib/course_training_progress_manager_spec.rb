# frozen_string_literal: true

require 'rails_helper'

describe CourseTrainingProgressManager do
  let(:user)     { create(:user, trained: trained) }
  let(:trained)  { true }
  let(:start)    { Date.new(2016, 1, 1) }
  let(:course)   { create(:course, start: start, timeline_start: start) }
  let(:cu)       { create(:courses_users, course_id: course.id, user_id: user.id) }

  let(:week)     { create(:week, course_id: course.id) }
  let(:due_date) { Date.new(2016, 2, 1) }
  let(:tm_ids)   { [1, 2] }
  let(:create_block_with_tm_ids) do
    create(:block, week_id: week.id, training_module_ids: tm_ids, due_date: due_date)
  end

  describe '#course_training_progress' do
    before do
      create_block_with_tm_ids
    end

    subject { described_class.new(user, course).course_training_progress }

    context 'course begins before December 1, 2015' do
      let(:start) { Date.new(2015, 1, 1) }
      context 'training boolean for user is complete' do
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'training boolean for user is nil' do
        let(:trained) { nil }
        it 'returns `Training Incomplete`' do
          expect(subject).to eq('Training Incomplete')
        end
      end
    end

    context 'course begins after December 1, 2015' do
      context '0 training modules assigned, 0 completed' do
        let(:tm_ids) { [] }
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context '1 training modules assigned, 1 completed' do
        let(:tm_ids) { [1] }
        before do
          tm_ids.each do |tm_id|
            create(:training_modules_users,
                   training_module_id: tm_id,
                   user_id: user.id)
          end
          TrainingModulesUsers.last.update_attribute(:completed_at, 1.hour.ago)
        end
        it 'returns "1/1 training modules completed"' do
          expect(subject).to eq('1/1 training module completed')
        end
      end

      context '2 training modules assigned, 1 completed' do
        let(:tm_ids) { [1, 2] }
        before do
          tm_ids.each do |tm_id|
            create(:training_modules_users,
                   training_module_id: tm_id,
                   user_id: user.id)
          end
          TrainingModulesUsers.last.update_attribute(:completed_at, 1.hour.ago)
        end
        it 'returns "1/2 training modules completed"' do
          expect(subject).to eq('1/2 training modules completed')
        end
      end
    end
  end

  describe '#incomplete_assigned_modules' do
    subject { described_class.new(user, course).incomplete_assigned_modules }

    context 'when there are no assigned modules' do
      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when all assigned modules are complete' do
      before do
        create_block_with_tm_ids
        tm_ids.each do |tm_id|
          create(:training_modules_users,
                 training_module_id: tm_id,
                 user_id: user.id,
                 completed_at: 1.hour.ago)
        end
      end

      it 'returns an empty array' do
        expect(subject).to eq([])
      end
    end

    context 'when some assigned modules are complete' do
      before do
        create_block_with_tm_ids
        create(:training_modules_users,
               training_module_id: 1,
               user_id: user.id,
               completed_at: 1.hour.ago)
      end

      it 'returns an array of only incomplete modules' do
        expect(subject.length).to eq(1)
      end
    end

    context 'when an incomplete module has a specific due date' do
      before do
        create_block_with_tm_ids
      end
      it 'returns an array with incomplete modules, with due date' do
        expect(subject.length).to eq(2)
        expect(subject[0].due_date.to_date).to eq(due_date)
      end
    end
    context 'when an incomplete module has no specific due date' do
      let(:due_date) { nil }
      before do
        create_block_with_tm_ids
      end
      it 'calculates the due date from timeline data' do
        # The assignment is in the first week, and the due date
        # is inferred to be the end of that week.
        expect(subject[0].due_date.to_date).to be > start
        expect(subject[0].due_date.to_date).to be < start + 1.week
      end
    end
  end
end
