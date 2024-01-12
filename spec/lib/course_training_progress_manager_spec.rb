# frozen_string_literal: true

require 'rails_helper'
require Rails.root.join('lib/course_training_progress_manager')

describe CourseTrainingProgressManager do
  before { TrainingModule.load_all }

  let(:user)     { create(:user, trained:) }
  let(:trained)  { true }
  let(:start)    { Date.new(2016, 1, 1) }
  let(:course)   { create(:course, start:, timeline_start: start) }
  let(:cu)       { create(:courses_users, course_id: course.id, user_id: user.id) }

  let(:week)     { create(:week, course_id: course.id) }
  let(:due_date) { Date.new(2016, 2, 1) }

  # Training Modules block
  let(:tm_ids)   { [1, 2] }
  let(:create_block_with_tm_ids) do
    create(:block, week_id: week.id, training_module_ids: tm_ids, due_date:)
  end

  # Exercise block
  let(:ex_ids) { [35, 37] }
  let(:create_block_with_ex_ids) do
    create(:block, week_id: week.id, training_module_ids: ex_ids, due_date:)
  end

  describe '#course_training_progress' do
    subject { described_class.new(course).course_training_progress(user) }

    before do
      create_block_with_tm_ids
    end

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
          TrainingModulesUsers.last.update(completed_at: 1.hour.ago)
        end

        it 'returns "1/1 training modules completed"' do
          expect(subject[:description]).to eq('1/1 training module completed')
          expect(subject[:assigned_count]).to eq(1)
          expect(subject[:completed_count]).to eq(1)
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
          TrainingModulesUsers.last.update(completed_at: 1.hour.ago)
        end

        it 'returns "1/2 training modules completed"' do
          expect(subject[:description]).to eq('1/2 training modules completed')
          expect(subject[:assigned_count]).to eq(2)
          expect(subject[:completed_count]).to eq(1)
        end
      end

      context '3 training modules assigned, 1 completed, 1 exercise' do
        let(:tm_ids) { [1, 2, 35] } # 35 is an exercise

        before do
          tm_ids.each do |tm_id|
            create(:training_modules_users,
                   training_module_id: tm_id,
                   user_id: user.id)
          end
          # Complete module 1 and 35
          TrainingModulesUsers.first.update(completed_at: 1.hour.ago)
          TrainingModulesUsers.last.update(completed_at: 1.hour.ago)
        end

        it 'returns "1/2 training modules completed"' do
          expect(subject[:description]).to eq('1/2 training modules completed')
          expect(subject[:assigned_count]).to eq(2)
          expect(subject[:completed_count]).to eq(1)
        end
      end
    end
  end

  describe '#course_exercise_progress' do
    subject { described_class.new(course).course_exercise_progress(user) }

    before do
      create_block_with_ex_ids
    end

    context 'course begins before December 1, 2015' do
      let(:start) { Date.new(2015, 1, 1) }

      context 'training boolean for user is complete' do
        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context 'training boolean for user is nil' do
        let(:trained) { nil }

        it 'returns nil' do
          expect(subject).to eq(nil)
        end
      end
    end

    context 'course begins after December 1, 2015' do
      context '0 training modules assigned, 0 completed' do
        let(:ex_ids) { [] }

        it 'returns nil' do
          expect(subject).to be_nil
        end
      end

      context '1 exercise assigned, 1 completed' do
        let(:ex_ids) { [35] }

        before do
          ex_ids.each do |tm_id|
            create(:training_modules_users,
                   training_module_id: tm_id,
                   user_id: user.id)
          end
          exercise = TrainingModulesUsers.last
          exercise.update(completed_at: 1.hour.ago)
          exercise.update(flags: { marked_complete: true })
        end

        it 'returns "1/1 exercise completed"' do
          expect(subject[:description]).to eq('1/1 exercise completed')
          expect(subject[:assigned_count]).to eq(1)
          expect(subject[:completed_count]).to eq(1)
        end
      end

      context '2 exercises assigned, 1 completed' do
        let(:ex_ids) { [35, 37] }

        before do
          ex_ids.each do |ex_id|
            create(:training_modules_users,
                   training_module_id: ex_id,
                   user_id: user.id)
          end
          exercise = TrainingModulesUsers.last
          exercise.update(completed_at: 1.hour.ago)
          exercise.update(flags: { marked_complete: true })
        end

        it 'returns "1/2 exercises completed"' do
          expect(subject[:description]).to eq('1/2 exercises completed')
          expect(subject[:assigned_count]).to eq(2)
          expect(subject[:completed_count]).to eq(1)
        end
      end

      context '3 modules assigned, 1 completed, 1 is training' do
        let(:ex_ids) { [1, 35, 37] } # 1 is a training module

        before do
          ex_ids.each do |ex_id|
            create(:training_modules_users,
                   training_module_id: ex_id,
                   user_id: user.id)
          end
          # Complete module 1 and 35
          TrainingModulesUsers.first.update(completed_at: 1.hour.ago)
          exercise = TrainingModulesUsers.last
          exercise.update(completed_at: 1.hour.ago)
          exercise.update(flags: { marked_complete: true })
        end

        it 'returns "1/2 exercises completed"' do
          expect(subject[:description]).to eq('1/2 exercises completed')
          expect(subject[:assigned_count]).to eq(2)
          expect(subject[:completed_count]).to eq(1)
        end
      end
    end
  end

  describe '#incomplete_assigned_modules' do
    subject { described_class.new(course).incomplete_assigned_modules(user) }

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
