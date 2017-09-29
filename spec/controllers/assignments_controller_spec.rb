# frozen_string_literal: true

require 'rails_helper'

describe AssignmentsController do
  let!(:course) { create(:course, id: 1) }
  let!(:user) { create(:user) }
  before do
    stub_wiki_validation
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe 'GET #index' do
    let!(:assignment) { create(:assignment, course_id: 1) }

    before do
      allow(Assignment).to receive(:where).and_return(assignment)
      get :index, params: { course_id: course.slug }
    end
    it 'sets assignments ivar' do
      expect(assigns(:assignments)).to eq(assignment)
    end
    it 'renders a json response' do
      expect(response.body).to eq(assignment.to_json)
    end
  end

  describe 'DELETE #destroy' do
    context 'when the user owns the assignment' do
      let(:assignment) do
        create(:assignment, course_id: course.id, user_id: user.id,
                            article_title: 'Selfie', role: 0)
      end

      before do
        expect_any_instance_of(WikiCourseEdits).to receive(:remove_assignment)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
      end

      context 'when the assignment_id is provided' do
        let(:params) { { course_id: course.slug } }
        before do
          delete :destroy, params: { id: assignment.id }.merge(params)
        end
        it 'destroys the assignment' do
          expect(Assignment.count).to eq(0)
        end

        it 'renders a json response' do
          id = assignment.id.to_s
          expect(response.body).to eq({ article: id }.to_json)
        end
      end

      context 'when the assignment_id is not provided' do
        let(:params) do
          { course_id: course.slug, user_id: user.id,
            article_title: assignment.article_title, role: assignment.role }
        end
        before do
          delete :destroy, params: { id: 'undefined' }.merge(params)
        end
        # This happens when an assignment is deleted right after it has been created.
        # The version in the AssignmentStore will not have an assignment_id until
        # it gets refreshed from the server.
        it 'deletes the assignment' do
          expect(Assignment.count).to eq(0)
        end
      end
    end

    context 'when the user does not have permission do destroy the assignment' do
      let(:assignment) { create(:assignment, course_id: course.id, user_id: user.id + 1) }
      let(:params) { { course_id: course.slug } }
      before do
        delete :destroy, params: { id: assignment }.merge(params)
      end

      it 'does not destroy the assignment' do
        expect(Assignment.count).to eq(1)
      end

      it 'renders a 401 status' do
        expect(response.status).to eq(401)
      end
    end

    context 'when parameters for a non-existent assignment are provided' do
      let(:assignment) { create(:assignment, course_id: course.id, user_id: user.id) }
      let(:params) do
        { course_id: course.slug, user_id: user.id + 1,
          article_title: assignment.article_title, role: assignment.role }
      end
      before do
        delete :destroy, params: { id: 'undefined' }.merge(params)
      end
      # This happens when an assignment is deleted right after it has been created.
      # The version in the AssignmentStore will not have an assignment_id until
      # it gets refreshed from the server.
      it 'renders a 404' do
        expect(response.status).to eq(404)
      end
    end
  end

  describe 'POST #create' do
    context 'when the user has permission to create the assignment' do
      let(:course) { create(:course) }
      let(:assignment_params) do
        { user_id: user.id, course_id: course.slug, title: 'pizza', role: 0 }
      end

      context 'when the article does not exist' do
        it 'imports the article and associates it with the assignment' do
          expect(Article.find_by(title: 'Pizza')).to be_nil

          VCR.use_cassette 'assignment_import' do
            expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
            expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
            put :create, params: assignment_params
            assignment = assigns(:assignment)
            expect(assignment).to be_a_kind_of(Assignment)
            expect(assignment.article.title).to eq('Pizza')
            expect(assignment.article.namespace).to eq(Article::Namespaces::MAINSPACE)
            expect(assignment.article.rating).not_to be_nil
            expect(assignment.article.updated_at).not_to be_nil
          end
        end
      end

      context 'when the assignment is for Wiktionary' do
        let!(:en_wiktionary) { create(:wiki, language: 'en', project: 'wiktionary') }
        let(:wiktionary_params) do
          { user_id: user.id, course_id: course.slug, title: 'selfie', role: 0,
            language: 'en', project: 'wiktionary' }
        end
        it 'imports the article with a lower-case title' do
          expect(Article.find_by(title: 'selfie')).to be_nil

          VCR.use_cassette 'assignment_import' do
            expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
            expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
            put :create, params: wiktionary_params
            assignment = assigns(:assignment)
            expect(assignment).to be_a_kind_of(Assignment)
            expect(assignment.article.title).to eq('selfie')
            expect(assignment.article.namespace).to eq(Article::Namespaces::MAINSPACE)
          end
        end
      end

      context 'when the assignment is for Wikisource' do
        let!(:www_wikisource) { create(:wiki, language: 'www', project: 'wikisource') }
        let(:wikisource_params) do
          { user_id: user.id, course_id: course.slug, title: 'Heyder Cansa', role: 0,
            language: 'www', project: 'wikisource' }
        end

        before do
          expect(Article.find_by(title: 'Heyder Cansa')).to be_nil
        end

        it 'imports the article' do
          VCR.use_cassette 'assignment_import' do
            expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
            expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
            put :create, params: wikisource_params
            assignment = assigns(:assignment)
            expect(assignment).to be_a_kind_of(Assignment)
            expect(assignment.article.title).to eq('Heyder_Cansa')
            expect(assignment.article.namespace).to eq(Article::Namespaces::MAINSPACE)
          end
        end
      end

      context 'when the assignment is for Wikimedia incubator' do
        let!(:wikimedia_incubator) { create(:wiki, language: 'incubator', project: 'wikimedia') }
        let(:wikimedia_params) do
          { user_id: user.id, course_id: course.slug, title: 'Wp/kiu/Heyder Cansa', role: 0,
            language: 'incubator', project: 'wikimedia' }
        end

        before do
          expect(Article.find_by(title: 'Wp/kiu/Heyder Cansa')).to be_nil
        end

        it 'imports the article' do
          VCR.use_cassette 'assignment_import' do
            expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
            expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
            put :create, params: wikimedia_params
            assignment = assigns(:assignment)
            expect(assignment).to be_a_kind_of(Assignment)
            expect(assignment.article.title).to eq('Wp/kiu/Heyder_Cansa')
            expect(assignment.article.namespace).to eq(Article::Namespaces::MAINSPACE)
          end
        end
      end

      context 'when the article exists' do
        before do
          create(:article, title: 'Pizza', namespace: Article::Namespaces::MAINSPACE)
        end

        it 'sets assignments ivar with a default wiki' do
          expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
          expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
          VCR.use_cassette 'assignment_import' do
            put :create, params: assignment_params
            assignment = assigns(:assignment)
            expect(assignment).to be_a_kind_of(Assignment)
            expect(assignment.wiki.language).to eq('en')
            expect(assignment.wiki.project).to eq('wikipedia')
          end
        end

        it 'renders a json response' do
          expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
          expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
          VCR.use_cassette 'assignment_import' do
            put :create, params: assignment_params
          end
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
        let(:es_wikibooks) { create(:wiki, language: 'es', project: 'wikibooks') }
        before do
          create(:article, title: 'Pizza', wiki_id: es_wikibooks.id,
                           namespace: Article::Namespaces::MAINSPACE)
        end

        it 'sets the wiki based on language and project params' do
          expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
          expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
          put :create, params: assignment_params_with_language_and_project
          assignment = assigns(:assignment)
          expect(assignment).to be_a_kind_of(Assignment)
          expect(assignment.wiki_id).to eq(es_wikibooks.id)
        end
      end
    end

    context 'when the user does not have permission to create the assignment' do
      let(:course) { create(:course) }
      let(:assignment_params) do
        { user_id: user.id + 1, course_id: course.slug, title: 'pizza', role: 0 }
      end
      before do
        put :create, params: assignment_params
      end

      it 'does not create the assignment' do
        expect(Assignment.count).to eq(0)
      end

      it 'renders a 401 status' do
        expect(response.status).to eq(401)
      end
    end

    context 'when the wiki params are not valid' do
      let(:course) { create(:course) }
      let(:invalid_wiki_params) do
        { user_id: user.id, course_id: course.slug, title: 'Pikachu', role: 0,
          language: 'en', project: 'bulbapedia' }
      end
      let(:subject) do
        put :create, params: invalid_wiki_params
      end
      it 'returns a 404 error message' do
        expect(subject.body).to have_content('Invalid assignment')
        expect(subject.status).to eq(404)
      end
    end

    context 'when the same assignment already exists' do
      let(:title) { 'My article' }
      let!(:assignment) do
        create(:assignment, course_id: course.id, user_id: user.id, role: 0, article_title: title)
      end
      let(:duplicate_assignment_params) do
        { user_id: user.id, course_id: course.slug, title: title, role: 0 }
      end
      before do
        VCR.use_cassette 'assignment_import' do
          put :create, params: duplicate_assignment_params
        end
      end

      it 'renders an error message with the article title' do
        expect(response.status).to eq(500)
        expect(response.body).to include('My_article')
      end
    end

    context 'when a case-variant of the assignment already exists' do
      let(:title) { 'My article' }
      let(:variant_title) { 'MY ARTICLE' }
      let!(:assignment) do
        create(:assignment, course_id: course.id, user_id: user.id, role: 0, article_title: title)
      end
      let(:case_variant_assignment_params) do
        { user_id: user.id, course_id: course.slug, title: variant_title, role: 0 }
      end
      before do
        expect_any_instance_of(WikiCourseEdits).to receive(:update_assignments)
        expect_any_instance_of(WikiCourseEdits).to receive(:update_course)
        VCR.use_cassette 'assignment_import' do
          put :create, params: case_variant_assignment_params
        end
      end

      it 'creates the case-variant assignment' do
        expect(response.status).to eq(200)
        expect(Assignment.last.article_title).to eq('MY_ARTICLE')
      end
    end
  end

  describe 'PATCH #update' do
    let(:assignment) { create(:assignment, course_id: course.id, user_id: user.id, role: 0) }
    let(:update_params) { { role: 1 } }

    context 'when the update succeeds' do
      it 'renders a 200' do
        post :update, params: { course_id: course.id, id: assignment }.merge(update_params), format: :json
        expect(response.status).to eq(200)
      end
    end
    context 'when the update fails' do
      it 'renders a 500' do
        allow_any_instance_of(Assignment).to receive(:save).and_return(false)
        post :update, params: { course_id: course.id, id: assignment }.merge(update_params), format: :json
        expect(response.status).to eq(500)
      end
    end
  end
end
