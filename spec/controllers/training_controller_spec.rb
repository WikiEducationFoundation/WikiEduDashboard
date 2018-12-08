# frozen_string_literal: true

require 'rails_helper'

describe TrainingController do
  let(:user) { create(:user) }
  let(:library_id) { 'students' }
  let(:module_id)  { TrainingModule.all.first.slug }

  before { TrainingModule.load_all }

  describe 'show' do
    subject { get :show, params: request_params }

    before  { allow(controller).to receive(:current_user).and_return(user) }

    let(:request_params) { { library_id: library_id } }

    context 'library is legit' do
      it 'sets the library' do
        subject
        expect(assigns(:library)).to be_an_instance_of(TrainingLibrary)
      end
    end

    context 'not a real library' do
      let(:library_id) { 'lolnotareallibrary' }

      it 'raises a module not found error' do
        expect { subject }.to raise_error ActionController::RoutingError
      end
    end
  end

  describe '#training_module' do
    subject { get :training_module, params: request_params }

    let(:request_params) do
      {
        library_id: library_id,
        module_id: module_id
      }
    end

    before { allow(controller).to receive(:current_user).and_return(user) }

    context 'module is legit' do
      it 'sets the presenter' do
        subject
        expect(assigns(:pres)).to be_an_instance_of(TrainingModulePresenter)
      end
    end

    context 'not a real module' do
      let(:module_id) { 'lolnotarealmodule' }

      it 'raises a module not found error' do
        expect { subject }.to raise_error ActionController::RoutingError
      end
    end
  end

  describe '#reload' do
    context 'for all modules' do
      let(:subject) { get :reload, params: { module: 'all' } }

      it 'returns the result upon success' do
        subject
        expect(response.body).to have_content 'Success!'
      end

      it 'displays an error message upon failure' do
        allow(TrainingModule).to receive(:load_all)
          .and_raise(TrainingBase::DuplicateIdError, 'oh noes!')
        subject
        expect(response.body).to have_content 'oh noes!'
      end
    end

    context 'for a single module, from wiki' do
      before do
        TrainingModule.delete_all
        TrainingSlide.delete_all
      end

      let(:subject) { get :reload, params: { module: 'plagiarism' } }

      it 'returns the result upon success' do
        allow(Features).to receive(:wiki_trainings?).and_return(true)
        VCR.use_cassette 'wiki_trainings' do
          subject
        end
        expect(response.body).to have_content 'Success!'
      end

      it 'displays an error message if the module does not exist' do
        get :reload, params: { module: 'image-and-medium' }
        expect(response.body).to have_content 'No module'
      end
    end
  end

  # Make sure default trainings get reloaded
end
