require 'rails_helper'

describe TrainingController do
  let(:user) { create(:user) }
  let(:library_id) { 'students' }
  let(:module_id)  { TrainingModule.all.first.slug }

  describe 'show' do
    before  { allow(controller).to receive(:current_user).and_return(user) }
    subject { get :show, request_params }
    let(:request_params) {{ library_id: library_id }}
    context 'library is legit' do
      it 'sets the library' do
        subject
        expect(assigns(:library)).to be_an_instance_of(TrainingLibrary)
      end
    end
    context 'not a real library' do
      let(:library_id) { 'lolnotareallibrary' }
      it 'raises a record not found error' do
        expect{ subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end

  describe '#training_module' do
    let(:request_params) {{
      library_id: library_id,
      module_id: module_id
    }}
    before { allow(controller).to receive(:current_user).and_return(user) }
    subject { get :training_module, request_params }
    context 'module is legit' do
      it 'sets the presenter' do
        subject
        expect(assigns(:pres)).to be_an_instance_of(TrainingModulePresenter)
      end
    end
    context 'not a real module' do
      let(:module_id) { 'lolnotarealmodule' }
      it 'raises a record not found error' do
        expect{ subject }.to raise_error ActiveRecord::RecordNotFound
      end
    end
  end
end
