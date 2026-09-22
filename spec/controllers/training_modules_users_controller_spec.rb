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

  describe '#mark_exercise_complete' do
    let(:course) { create(:course) }
    let(:week) { create(:week, course:) }
    let(:user) { create(:user, username: 'Ragesock') }
    let(:training_module) { TrainingModule.find_by(slug: module_slug) }
    let(:block) { create(:block, week:, training_module_ids: [training_module.id]) }
    let(:request_params) do
      { block_id: block.id, complete: true, module_id: training_module.slug }
    end
    let(:flags) { TrainingModulesUsers.last.flags[course.id] }

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    context 'when the exercise expects no page' do
      let(:module_slug) { 'copyedit-exercise' }

      before do
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end

      it 'marks the exercise complete' do
        expect(flags[:marked_complete]).to eq(true)
      end
    end

    context 'when the expected userpage sandbox exists' do
      let(:module_slug) { 'choose-topic-exercise' }
      let(:user) { create(:user, username: 'Kmblim') }

      before do
        VCR.use_cassette 'exercise_sandbox/user_sandbox' do
          post '/training_modules_users/exercise.json', params: request_params, as: :json
        end
      end

      it 'marks the exercise complete' do
        expect(flags[:marked_complete]).to eq(true)
      end
    end

    context 'when the expected userpage sandbox does not exist' do
      let(:module_slug) { 'choose-topic-exercise' }

      before do
        VCR.use_cassette 'exercise_sandbox/user_sandbox' do
          post '/training_modules_users/exercise.json', params: request_params, as: :json
        end
      end

      it 'refuses the request' do
        expect(response.status).to eq(403)
      end

      it 'does not mark the exercise complete' do
        expect(flags).to be_nil
      end

      it 'names the expected page' do
        expect(response.parsed_body['message'])
          .to include('User:Ragesock/Choose_an_Article')
      end
    end

    context 'when the expected bibliography page does not exist' do
      let(:module_slug) { 'bibliography-exercise' }

      before do
        create(:assignment, course:, user:, wiki_id: 1,
                            role: Assignment::Roles::ASSIGNED_ROLE,
                            sandbox_url: 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox')
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          post '/training_modules_users/exercise.json', params: request_params, as: :json
        end
      end

      it 'refuses the request' do
        expect(response.status).to eq(403)
      end

      it 'names the expected page' do
        expect(response.parsed_body['message'])
          .to include('User:Ragesock/student_sandbox/Bibliography')
      end
    end

    context 'when the expected bibliography page exists' do
      let(:module_slug) { 'bibliography-exercise' }

      before do
        create(:assignment, course:, user:, wiki_id: 1,
                            role: Assignment::Roles::ASSIGNED_ROLE,
                            sandbox_url: 'https://en.wikipedia.org/wiki/User:Ragesock/student_sandbox_empty')
        VCR.use_cassette 'exercise_sandbox/assignment_sandbox' do
          post '/training_modules_users/exercise.json', params: request_params, as: :json
        end
      end

      it 'marks the exercise complete' do
        expect(flags[:marked_complete]).to eq(true)
      end
    end

    context 'when unmarking an exercise whose expected page does not exist' do
      let(:module_slug) { 'choose-topic-exercise' }
      let(:request_params) do
        { block_id: block.id, complete: false, module_id: training_module.slug }
      end

      before do
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end

      it 'marks the exercise incomplete' do
        expect(flags[:marked_complete]).to eq(false)
      end

      it 'does not query the wiki' do
        expect(WikiApi).not_to receive(:new)
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end
    end

    context 'when the student has not assigned themselves an article yet' do
      let(:module_slug) { 'bibliography-exercise' }

      before do
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end

      it 'refuses the request' do
        expect(response.status).to eq(403)
      end

      it 'does not mark the exercise complete' do
        expect(flags).to be_nil
      end
    end

    context 'when the article title for an article_title_input exercise is unverified' do
      let(:module_slug) { 'update-a-biography-exercise' }

      before do
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end

      it 'refuses the request' do
        expect(response.status).to eq(403)
      end

      it 'returns the article verification message' do
        expect(response.parsed_body['message']).to include('verify your Wikipedia edit')
      end
    end

    context 'when the article title for an article_title_input exercise is verified' do
      let(:module_slug) { 'update-a-biography-exercise' }

      before do
        tmu = TrainingModulesUsers.create(user:, training_module:)
        tmu.store_exercise_article_title('Selfie')
        tmu.save
        post '/training_modules_users/exercise.json', params: request_params, as: :json
      end

      it 'marks the exercise complete' do
        expect(flags[:marked_complete]).to eq(true)
      end
    end
  end

  describe '#verify_exercise_article' do
    let(:user) { create(:user) }
    let(:training_module) { TrainingModule.find_by(slug: 'update-a-biography-exercise') }
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
