require 'rails_helper'

describe AssignmentsController do
  let!(:course) { create(:course, id: 1) }
  let!(:user) { create(:user) }
  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET index' do
    let!(:assignment) { create(:assignment, course_id: 1) }

    before do
      allow(Assignment).to receive(:where).and_return(assignment)
      get :index, course_id: course.slug
    end
    it 'sets assignments ivar' do
      expect(assigns(:assignments)).to eq(assignment)
    end
    it 'renders a json response' do
      expect(response.body).to eq(assignment.to_json)
    end
  end

  describe 'DELETE destroy' do
    context 'when the user owns the assignment' do
      let(:assignment) { create(:assignment, course_id: course.id, user_id: user.id) }
      before do
        expect_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
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

    context 'when the user does not have permission do destroy the assignment' do
      let(:assignment) { create(:assignment, course_id: course.id, user_id: user.id + 1) }
      before do
        delete :destroy, id: assignment.id
      end

      it 'does not destroy the assignment' do
        expect(Assignment.count).to eq(1)
      end

      it 'renders a 401 status' do
        expect(response.status).to eq(401)
      end
    end
  end

  describe 'create' do
    context 'when the user has permission to create the assignment' do
      let(:course) { create(:course) }
      let(:assignment_params) do
        { user_id: user.id, course_id: course.slug, title: 'pizza', role: 0 }
      end

      it 'sets assignments ivar with a default wiki' do
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
        put :create, assignment_params
        assignment = assigns(:assignment)
        expect(assignment).to be_a_kind_of(Assignment)
        expect(assignment.wiki.language).to eq('en')
        expect(assignment.wiki.project).to eq('wikipedia')
      end
      it 'renders a json response' do
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
        put :create, assignment_params
        json_response = JSON.parse(response.body)
        # response makes created_at differ by milliseconds, which is weird,
        # so test attrs that actually matter rather than whole record
        expect(json_response['article_title'])
          .to eq(Assignment.last.article_title)
        expect(json_response['user_id']).to eq(Assignment.last.user_id)
        expect(json_response['role']).to eq(Assignment.last.role)
      end

      let(:assignment_params_with_language_and_project) do
        { user_id: user.id, course_id: course.slug, title: 'pizza',
          role: 0, language: 'es', project: 'wikibooks' }
      end
      let!(:es_wikibooks) { create(:wiki, language: 'es', project: 'wikibooks') }

      it 'sets the wiki based on language and project params' do
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
        put :create, assignment_params_with_language_and_project
        assignment = assigns(:assignment)
        expect(assignment).to be_a_kind_of(Assignment)
        expect(assignment.wiki_id).to eq(es_wikibooks.id)
      end
    end

    context 'when the user does not have permission to create the assignment' do
      let(:course) { create(:course) }
      let(:assignment_params) do
        { user_id: user.id + 1, course_id: course.slug, title: 'pizza', role: 0 }
      end
      before do
        put :create, assignment_params
      end

      it 'does not create the assignment' do
        expect(Assignment.count).to eq(0)
      end

      it 'renders a 401 status' do
        expect(response.status).to eq(401)
      end
    end
  end
end
