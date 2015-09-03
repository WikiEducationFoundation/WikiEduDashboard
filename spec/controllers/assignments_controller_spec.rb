require 'rails_helper'

describe AssignmentsController do
  describe 'GET index' do
    let!(:assignment) { create(:assignment) }
    before do
      allow(Course).to receive(:find_by_slug).and_return(OpenStruct.new(id: 1))
      allow(Assignment).to receive(:where).and_return(assignment)
      get :index, course_id: 'foobar'
    end
    it 'sets assignments ivar' do
      expect(assigns(:assignments)).to eq(assignment)
    end
    it 'renders a json response' do
      expect(response.body).to eq(assignment.to_json)
    end
  end

  describe 'DELETE destroy' do
    let!(:assignment) { create(:assignment) }
    before do
      allow(Assignment).to receive(:find).and_return(assignment)
      delete :destroy, id: assignment.id
    end
    it 'destroys the assignment' do
      expect(Assignment.count).to eq(0)
    end

    it 'renders a json response' do
      id = assignment.id.to_s
      expect(response.body).to eq({ article: id }.to_json)
    end
  end

  describe 'create' do
    let(:assignment_params) do
      { user_id: 1, course_id: 1, article_title: 'pizza', role: 0 }
    end
    before do
      allow(Course).to receive(:find_by_slug).and_return(OpenStruct.new(id: 1))
    end
    it 'sets assignments ivar' do
      put :create, assignment_params
      expect(assigns(:assignment)).to be_a_kind_of(Assignment)
    end
    it 'renders a json response' do
      put :create, assignment_params
      json_response = JSON.parse(response.body)
      # response makes created_at differ by milliseconds, which is weird,
      # so test attrs that actually matter rather than whole record
      expect(json_response['article_title'])
        .to eq(Assignment.last.article_title)
      expect(json_response['user_id']).to eq(Assignment.last.user_id)
      expect(json_response['role']).to eq(Assignment.last.role)
    end
  end
end
