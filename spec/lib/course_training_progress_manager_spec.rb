require 'rails_helper'

describe CourseTrainingProgressManager do
  let(:user)     { create(:user) }
  let(:course)   { create(:course) }
  let(:cu)       { create(:courses_users, course_id: course.id, user_id: user.id) }

  let(:week)     { create(:week, course_id: course.id) }
  let(:due_date) { 1.week.from_now }
  let(:tm_ids)   { [1, 2] }
  let!(:block)  do
    create(:block, week_id: week.id, training_module_ids: tm_ids, due_date: due_date)
  end

  describe '#course_training_progress' do
    subject { described_class.new(user, course).course_training_progress }

    context '0 training modules assigned, 0 completed' do
      let(:tm_ids) { [] }
      it 'returns "0/0 training modules completed"' do
        expect(subject).to eq("0/0 training modules completed")
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
        expect(subject).to eq("1/1 training modules completed")
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
        expect(subject).to eq("1/2 training modules completed")
      end
    end
  end

  describe '#next_upcoming_assigned_module' do
    subject { described_class.new(user, course).next_upcoming_assigned_module }
    context 'no upcoming modules' do
      let(:due_date) { 1.week.ago }
      it 'returns nil' do
        expect(subject).to be_nil
      end
    end
    context 'upcoming modules' do
      let(:tm_ids) { [3] }
      context '1 module' do
        context 'module is not completed' do
          it 'returns an OpenStruct with relevant data' do
            tm = TrainingModule.find(tm_ids.first)
            expect(subject.title).to eq(tm.name)
            expect(subject.due_date).to eq(block.due_date)
            expect(subject.link).to eq("/library/students/#{tm.slug}")
          end
        end

        context 'module is completed' do
          let!(:tmu) do create(:training_modules_users,
            training_module_id: tm_ids.first,
            user_id: user.id,
            completed_at: 2.days.ago)
          end
          it 'returns nil' do
            expect(subject).to be_nil
          end
        end
      end
      context '2 blocks, each with a module, different due dates' do
        let(:tm_ids)  { [3] }
        let(:tm_ids2) { [2] }
        let!(:block2)  do
          create(:block, week_id: week.id, training_module_ids: tm_ids2, due_date: 2.days.from_now)
        end
        it 'returns the first module by due date' do
          tm = TrainingModule.find(tm_ids2.first)
          expect(subject.title).to eq(tm.name)
          expect(subject.due_date).to eq(block2.due_date)
          expect(subject.link).to eq("/library/students/#{tm.slug}")
        end
      end
    end
  end
end
