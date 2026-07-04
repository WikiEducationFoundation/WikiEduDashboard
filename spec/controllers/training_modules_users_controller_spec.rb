# frozen_string_literal: true

require 'rails_helper'

describe TrainingModulesUsersController, type: :request do
  describe '#create_or_update' do
    before { TrainingModule.load_all }
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

  describe '#mark_exercise_complete' do
    let(:user) { create(:user) }
    let(:course) { create(:course) }
    let(:week) { create(:week, course: course) }
    let(:block) { create(:block, week: week) }
    let(:training_module) do
      TrainingModule.find_by(slug: 'update-a-biography-exercise') ||
        create(:training_module, slug: 'update-a-biography-exercise',
                                 settings: { 'article_title_input' => true }, kind: 1)
    end
    let!(:tmu) do
      TrainingModulesUsers.create(user_id: user.id, training_module_id: training_module.id)
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'when article_title_input has not been verified' do
      before do
        post '/training_modules_users/exercise',
             params: { module_id: training_module.slug, block_id: block.id, complete: true }
      end

      it 'returns forbidden status' do
        expect(response.status).to eq(403)
      end

      it 'returns the article verification message' do
        expect(response.parsed_body['message']).to include('verify your Wikipedia edit')
      end
    end

    context 'when article title has already been verified' do
      before do
        tmu.store_exercise_article_title('Selfie')
        tmu.save
        post '/training_modules_users/exercise',
             params: { module_id: training_module.slug, block_id: block.id, complete: true }
      end

      it 'does not return forbidden' do
        expect(response.status).not_to eq(403)
      end
    end
  end

  describe '#verify_exercise_article' do
    let(:user) { create(:user) }
    let(:training_module) do
      TrainingModule.find_by(slug: 'update-a-biography-exercise') ||
        create(:training_module, slug: 'update-a-biography-exercise',
                                 settings: { 'article_title_input' => true }, kind: 1)
    end
    let!(:tmu) do
      TrainingModulesUsers.create(user_id: user.id, training_module_id: training_module.id)
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'when the user has edited the article' do
      before do
        allow_any_instance_of(WikiApi).to receive(:user_has_edited_article?).and_return(true)
        post '/training_modules_users/verify_exercise_article',
             params: { module_id: training_module.slug, article_title: 'Selfie' }
      end

      it 'returns verified status' do
        expect(response.parsed_body['status']).to eq('verified')
      end

      it 'saves the article title in flags' do
        expect(tmu.reload.flags['exercise_article_title']).to eq('Selfie')
      end
    end

    context 'when the user has not edited the article' do
      before do
        allow_any_instance_of(WikiApi).to receive(:user_has_edited_article?).and_return(false)
        post '/training_modules_users/verify_exercise_article',
             params: { module_id: training_module.slug, article_title: 'SomeArticle' }
      end

      it 'returns not_found status' do
        expect(response.parsed_body['status']).to eq('not_found')
      end

      it 'does not save the article title in flags' do
        expect(tmu.reload.flags['exercise_article_title']).to be_nil
      end
    end

    context 'when the user is enrolled as a student in a course with this module' do
      let(:course) { create(:course) }
      let(:week) { create(:week, course: course) }
      let!(:block) { create(:block, week: week, training_module_ids: [training_module.id]) }
      let!(:courses_user) do
        create(:courses_user, course: course, user: user, role: CoursesUsers::Roles::STUDENT_ROLE)
      end

      before do
        allow_any_instance_of(WikiApi).to receive(:user_has_edited_article?).and_return(true)
        post '/training_modules_users/verify_exercise_article',
             params: { module_id: training_module.slug,
                       article_title: 'Computational neuroscience' }
      end

      it 'auto-marks the exercise complete for the course' do
        expect(tmu.reload.flags[course.id]).to include(marked_complete: true)
      end
    end
  end
end
