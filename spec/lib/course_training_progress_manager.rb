require 'rails_helper'

describe CourseTrainingProgressManager do
  let(:user)    { create(:user) }
  let(:course)  { create(:course) }
  let(:cu)      { create(:courses_users, course_id: course.id, user_id: user.id) }

  let(:week)    { create(:week, course_id: course.id) }
  let!(:block)  { create(:block, week_id: week.id, training_module_ids: tm_ids) }

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

end
