# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsersController, type: :request do
  before { TrainingModule.load_all }

  describe '#create_or_update' do
    let(:user) { create(:user) }
    let(:training_module) { TrainingModule.find_by(slug: 'editing-basics') }
    let(:slide) { TrainingModule.find(training_module.id).slides.first }
    let!(:tmu) do
      TrainingModulesUsers.create(user_id: user.id, training_module_id: training_module.id)
    end

    let(:request_params1) do
      { user_id: user.id, module_id: training_module.slug, slide_id: slide.slug }
    end

    context 'tmu record exists' do
      context 'current slide has an index higher than last slide completed, set slide completed' do
        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
          post '/training_modules_users', params: request_params1
        end

        it 'sets last slide completed' do
          expect(TrainingModulesUsers.last.last_slide_completed)
            .to eq(slide.slug)
        end
      end

      context 'current slide has an index higher than last slide completed, maintain last slide' do
        # Like, go to slide 5 and go back to 3. last_slide_completed
        # should still be 5
        let(:slide) { TrainingModule.find(training_module.id).slides.last }
        let(:request_params2) do
          { user_id: user.id,
            module_id: training_module.slug,
            slide_id: TrainingModule.find(training_module.id).slides.first.slug }
        end

        before do
          allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
          post '/training_modules_users', params: request_params1
          post '/training_modules_users', params: request_params2
        end

        it 'maintains last_slide_completed' do
          expect(TrainingModulesUsers.last.last_slide_completed)
            .to eq(slide.slug)
        end
      end
    end

    context 'no tmu record exists' do
      let(:tmu) { nil }

      before do
        allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
        post '/training_modules_users', params: request_params1
      end

      it 'creates a TrainingModulesUser' do
        expect(TrainingModulesUsers.count).to eq(1)
      end

      it 'sets the correct module_id' do
        expect(TrainingModulesUsers.last.training_module_id)
          .to eq(training_module.id)
      end
    end
  end
end
