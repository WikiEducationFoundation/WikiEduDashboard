# frozen_string_literal: true

require 'rails_helper'

describe TrainingStatusController, type: :request do
  before { TrainingModule.load_all }

  describe '#show' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:week) { create(:week, course_id: course.id) }
    let!(:block) { create(:block, week_id: week.id, training_module_ids: [1]) }
    let!(:courses_user) do
      create(:courses_user, course_id: course.id, user_id: user.id,
                            role: CoursesUsers::Roles::STUDENT_ROLE)
    end

    let(:status_params) do
      { user_id: user.id, course_id: course.id, format: :json }
    end

    context 'when the training is incomplete' do
      it 'includes the not completed status for a user' do
        get '/training_status', params: status_params
        response_data = Oj.load(response.body)
        expect(response_data['course']['training_modules'][0]['status']).to eq('Not started')
        expect(response_data['course']['training_modules'][0]['completion_date']).to be_nil
      end
    end

    context 'when the training is complete' do
      let(:completion_date) { Time.zone.now }

      before do
        create(:training_modules_users, training_module_id: 1,
                                        completed_at: completion_date, user_id: user.id)
      end

      it 'includes the completion date' do
        get '/training_status', params: status_params
        response_data = Oj.load(response.body)
        expect(response_data['course']['training_modules'][0]['completion_date']).not_to be_nil
      end
    end
  end
end
