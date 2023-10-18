# frozen_string_literal: true

require 'rails_helper'

describe TrainingController, type: :request do
  let(:user) { create(:user) }
  let(:library_id) { 'students' }
  let(:module_id)  { TrainingModule.all.first.slug }

  before { TrainingModule.load_all }

  describe 'show' do
    subject { get "/training/#{library_id}", params: request_params }

    before  do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

    let(:request_params) { { library_id: } }

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
    subject { get "/training/#{library_id}/#{module_id}", params: request_params }

    let(:request_params) do
      {
        library_id:,
        module_id:
      }
    end

    before do
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    end

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

  describe 'add_library_breadcrumbs' do
    let(:content_class) { TrainingLibrary }

    before do
      allow(content_class).to receive(:wiki_base_page)
        .and_return('Training modules/dashboard/libraries-dev')
      allow(I18n).to receive(:locale).and_return(:de)
      allow(Features).to receive(:wiki_trainings?).and_return(true)
      content_class.destroy_all
      VCR.use_cassette 'training/load_from_wiki' do
        content_class.load
      end
    end

    context 'for wiki eduction' do
      before do
        allow(Features).to receive(:wiki_ed?).and_return(true)
      end

      it 'uses library id to make the breadcrumb' do
        get '/training/editing-wikipedia'
        expect(response.body).to include('Editing Wikipedia')
      end
    end

    context 'for non-wiki' do
      before do
        allow(Features).to receive(:wiki_ed?).and_return(false)
      end

      it 'uses translated name to make the breadcrumb' do
        get '/training/editing-wikipedia'
        expect(response.body).to include('Zweck dieses Moduls')
      end
    end
  end

  describe '#reload' do
    context 'for all modules' do
      let(:subject) { get '/reload_trainings', params: { module: 'all' } }

      it 'returns the result upon success' do
        subject
        expect(response.body).to include('Success!')
      end

      it 'displays an error message upon failure' do
        allow(TrainingModule).to receive(:load_all)
          .and_raise(TrainingBase::DuplicateSlugError, 'oh noes!')
        subject
        expect(response.body).to include('oh noes!')
      end
    end

    context 'for a single module, from wiki' do
      before do
        TrainingModule.delete_all
        TrainingSlide.delete_all
      end

      let(:subject) { get '/reload_trainings', params: { module: 'plagiarism' } }

      it 'returns the result upon success' do
        allow(Features).to receive(:wiki_trainings?).and_return(true)
        VCR.use_cassette 'wiki_trainings' do
          subject
        end
        expect(response.body).to include('Success!')
      end

      it 'displays an error message if the module does not exist' do
        get '/reload_trainings', params: { module: 'image-and-medium' }
        expect(response.body).to include('No module')
      end
    end
  end

  describe '#find' do
    subject { get "/find_training_module/#{module_id}" }

    context 'module_id is found' do
      let(:module_id) { 12 }

      it 'redirects to a training module page' do
        subject
        expect(response).to redirect_to('/training/students/peer-review')
      end
    end

    context 'module_id is found but it is in no library' do
      let(:module_id) { 2 }

      it 'uses a default library to build the route' do
        subject
        expect(response).to redirect_to('/training/instructors/editing-basics')
      end
    end

    context 'module_id is not found' do
      let(:module_id) { 128456 }

      it 'raises a module not found error' do
        expect { subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe '#find_slide' do
    subject { get "/find_training_slide/#{slide_id}" }

    context 'slide_id is found' do
      let(:slide_id) { 103 }

      it 'redirects to a training slide page' do
        subject
        expect(response).to redirect_to('/training/students/wikipedia-essentials/five-pillars')
      end
    end

    context 'slide_id is found but it is in no module' do
      let(:slide) { create(:training_slide) }
      let(:slide_id) { slide.id }

      it 'raises a routing error' do
        expect { subject }.to raise_error ActionController::RoutingError, 'module not found'
      end
    end

    context 'slide_id is found but its module is in no library' do
      let(:slide_id) { 201 }

      it 'uses a default library to build the route' do
        subject
        expect(response).to redirect_to('/training/instructors/editing-basics/welcome-students')
      end
    end

    context 'slide_id is not found' do
      let(:slide_id) { 128456 }

      it 'raises a module not found error' do
        expect { subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
