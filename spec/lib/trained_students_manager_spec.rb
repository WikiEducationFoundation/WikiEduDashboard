# frozen_string_literal: true

require 'rails_helper'

describe TrainedStudentsManager do
  let(:course)    { create(:course) }
  let(:week)      { create(:week, course_id: course.id) }
  let!(:block) do
    create(:block, week_id: week.id, due_date: 2.days.ago, training_module_ids: ids)
  end
  let(:user)      { create(:user) }
  let(:course_id) { course&.id }
  let!(:cu)       { create(:courses_user, course_id: course_id, user_id: user.id) }
  let(:t_mod)     { TrainingModule.all.first }
  let(:ids)       { [t_mod.id] }
  let!(:tmu) do
    create(:training_modules_users,
           training_module_id: t_mod.id,
           user_id: user.id,
           completed_at: completed_at)
  end
  let(:completed_at) { 1.week.ago.to_date }

  describe '#students_up_to_date_with_training' do
    subject { described_class.new(course).students_up_to_date_with_training }
    context 'no trainings assigned' do
      let(:ids) { nil }
      it 'returns all students' do
        expect(subject).not_to be_empty
      end
    end
    context 'no students in course' do
      let(:course_id) { nil }
      it 'returns empty array' do
        expect(subject).to be_empty
      end
    end
    context 'no overdue trainings' do
      it 'includes the user' do
        expect(subject).to include(user)
      end
    end
    context 'training is overdue' do
      let(:completed_at) { nil }
      it 'does not include user' do
        expect(subject).not_to include(user)
      end
    end
  end
end
