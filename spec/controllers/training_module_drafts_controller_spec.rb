# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TrainingModuleDraftsController, type: :controller do
  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:tmp_dir) { Rails.root.join('tmp', 'training_module_drafts_controller_spec') }

  before do
    FileUtils.rm_rf(tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    stub_const('TrainingModuleDraft::DIRNAME', tmp_dir.relative_path_from(Rails.root).to_s)
  end

  after { FileUtils.rm_rf(tmp_dir) }

  describe 'authorization' do
    it 'returns 401 for a non-admin on index' do
      allow(controller).to receive(:current_user).and_return(user)
      get :index
      expect(response.status).to eq(401)
    end

    it 'returns 401 for a non-admin on create' do
      allow(controller).to receive(:current_user).and_return(user)
      post :create, params: { draft: { name: 'New module' } }
      expect(response.status).to eq(401)
    end

    it 'returns 401 for a non-admin on parse_paste' do
      allow(controller).to receive(:current_user).and_return(user)
      post :parse_paste, params: { markdown: "## x\n" }
      expect(response.status).to eq(401)
    end

    it 'returns 401 for a non-admin on existing_slide_slugs' do
      allow(controller).to receive(:current_user).and_return(user)
      get :existing_slide_slugs, format: :json
      expect(response.status).to eq(401)
    end

    it 'returns 401 for a non-admin on export' do
      allow(controller).to receive(:current_user).and_return(user)
      get :export, params: { slug: 'whatever' }
      expect(response.status).to eq(401)
    end
  end

  context 'as an admin' do
    before { allow(controller).to receive(:current_user).and_return(admin) }

    describe '#create' do
      it 'creates a draft and responds with the draft data' do
        post :create, params: { draft: { name: 'My new module' } }
        expect(response).to have_http_status(:created)
        body = response.parsed_body
        expect(body.dig('draft', 'slug')).to eq('my-new-module')
        expect(body.dig('draft', 'module_id')).to be_a(Integer)
      end

      it 'refuses to create a duplicate slug' do
        TrainingModuleDraft.new(slug: 'taken', name: 'Taken').save
        post :create, params: { draft: { slug: 'taken', name: 'Other' } }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'rejects an invalid slug' do
        post :create, params: { draft: { slug: '../evil', name: 'Evil' } }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe '#index' do
      it 'lists drafts as JSON' do
        TrainingModuleDraft.new(slug: 'alpha', name: 'Alpha').save
        TrainingModuleDraft.new(slug: 'beta', name: 'Beta').save
        get :index, format: :json
        slugs = response.parsed_body['drafts'].map { |d| d['slug'] }
        expect(slugs).to contain_exactly('alpha', 'beta')
      end

      it 'renders the HTML shell for browser requests' do
        get :index
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to start_with('text/html')
      end
    end

    describe '#show' do
      it 'returns the draft as JSON' do
        TrainingModuleDraft.new(slug: 'alpha', name: 'Alpha',
                                slides: [{ 'slug' => 's1', 'title' => 'T',
                                           'content' => 'Body' }]).save
        get :show, params: { slug: 'alpha' }, format: :json
        expect(response.parsed_body.dig('draft', 'name')).to eq('Alpha')
        expect(response.parsed_body.dig('draft', 'slides').length).to eq(1)
      end

      it '404s on missing draft' do
        get :show, params: { slug: 'nonexistent' }, format: :json
        expect(response).to have_http_status(:not_found)
      end

      it 'renders the HTML shell for browser requests' do
        TrainingModuleDraft.new(slug: 'alpha', name: 'Alpha').save
        get :show, params: { slug: 'alpha' }
        expect(response).to have_http_status(:ok)
        expect(response.content_type).to start_with('text/html')
      end
    end

    describe '#update' do
      it 'updates fields and slides' do
        TrainingModuleDraft.new(slug: 'alpha', name: 'Alpha').save
        patch :update, params: {
          slug: 'alpha',
          draft: {
            name: 'Renamed',
            slides: [{ slug: 's1', title: 'T', content: 'Body' }]
          }
        }
        expect(response).to have_http_status(:ok)
        draft = TrainingModuleDraft.find('alpha')
        expect(draft.name).to eq('Renamed')
        expect(draft.slides.first['title']).to eq('T')
      end

      it 'renames the draft when a new slug is provided' do
        TrainingModuleDraft.new(slug: 'before', name: 'Before').save
        patch :update, params: {
          slug: 'before',
          draft: { slug: 'after', name: 'After' }
        }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body.dig('draft', 'slug')).to eq('after')
        expect(TrainingModuleDraft.exists?('before')).to be(false)
        expect(TrainingModuleDraft.exists?('after')).to be(true)
      end

      it 'returns 422 when the target slug is taken' do
        TrainingModuleDraft.new(slug: 'taken', name: 'T').save
        TrainingModuleDraft.new(slug: 'source', name: 'S').save
        patch :update, params: {
          slug: 'source',
          draft: { slug: 'taken' }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(TrainingModuleDraft.exists?('source')).to be(true)
      end

      it 'does not persist content updates when a rename collides' do
        TrainingModuleDraft.new(slug: 'taken', name: 'Taken').save
        TrainingModuleDraft.new(slug: 'source', name: 'Original').save
        patch :update, params: {
          slug: 'source',
          draft: { slug: 'taken', name: 'Edited name' }
        }
        expect(response).to have_http_status(:unprocessable_content)
        # Original draft is unchanged — edits are dropped, not silently saved
        # under the old slug.
        expect(TrainingModuleDraft.find('source').name).to eq('Original')
      end
    end

    describe '#destroy' do
      it 'removes the draft' do
        TrainingModuleDraft.new(slug: 'gone', name: 'Gone').save
        delete :destroy, params: { slug: 'gone' }
        expect(response).to have_http_status(:ok)
        expect(TrainingModuleDraft.exists?('gone')).to be(false)
      end
    end

    describe '#parse_paste' do
      it 'returns parsed slides for valid input' do
        post :parse_paste, params: { markdown: "## Hello\nworld\n" }
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['slides'].length).to eq(1)
      end

      it 'returns 422 for invalid input' do
        post :parse_paste, params: { markdown: "no heading here\n" }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    describe '#export' do
      it 'returns a zip attachment' do
        TrainingModuleDraft.new(
          slug: 'alpha', name: 'Alpha',
          slides: [{ 'slug' => 's1', 'title' => 'T', 'content' => 'C' }]
        ).save
        get :export, params: { slug: 'alpha' }
        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Type']).to eq('application/zip')
        expect(response.headers['Content-Disposition']).to include('attachment')
        expect(response.body[0, 2]).to eq('PK') # Zip magic number
      end
    end

    describe '#collisions' do
      it 'returns the list of colliding slide slugs' do
        create(:training_slide, slug: 'intro')
        TrainingModuleDraft.new(
          slug: 'alpha', name: 'Alpha',
          slides: [{ 'slug' => 'intro', 'title' => 'Intro', 'content' => '' }]
        ).save
        get :collisions, params: { slug: 'alpha' }
        expect(response.parsed_body['collisions']).to eq(['intro'])
      end
    end

    describe '#existing_slide_slugs' do
      it 'returns every TrainingSlide slug without being shadowed by the show route' do
        create(:training_slide, id: 900001, slug: 'slide-a')
        create(:training_slide, id: 900002, slug: 'slide-b')
        get :existing_slide_slugs, format: :json
        expect(response).to have_http_status(:ok)
        expect(response.parsed_body['slugs']).to include('slide-a', 'slide-b')
      end
    end
  end
end
