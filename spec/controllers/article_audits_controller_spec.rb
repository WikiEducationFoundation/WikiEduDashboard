# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/article_auditing/rendered_article"

describe ArticleAuditsController, type: :controller do
  render_views

  let(:admin) { create(:admin) }
  let(:user) { create(:user) }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:audit) {
 ArticleAudit.create!(wiki:, mw_rev_id: 123, article_title: 'Acme', requester: admin) }

  def sign_in_as(signed_in_user)
    allow_any_instance_of(ApplicationController)
      .to receive(:current_user).and_return(signed_in_user)
  end

  before { allow(Features).to receive(:article_audit?).and_return(true) }

  describe 'access' do
    it 'rejects non-admins' do
      sign_in_as(user)
      get :index, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'lets non-admins view a report, flagged as non-admin' do
      sign_in_as(user)
      allow(ArticleAuditing::RenderedArticle).to receive(:fetch).and_return(nil)
      get :show, params: { id: audit.id }, format: :json
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to include('admin' => false)
    end

    it 'tells search engines not to index reports' do
      sign_in_as(user)
      allow(ArticleAuditing::RenderedArticle).to receive(:fetch).and_return(nil)
      get :show, params: { id: audit.id }
      expect(response.headers['X-Robots-Tag']).to eq('noindex, nofollow')
    end

    it 'rejects non-admin re-runs' do
      sign_in_as(user)
      post :rerun_check, params: { id: audit.id, check_key: 'tone' }, format: :json
      expect(response).to have_http_status(:unauthorized)
    end

    it 'is not found when the feature is off' do
      allow(Features).to receive(:article_audit?).and_return(false)
      sign_in_as(admin)
      get :index, format: :json
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET #index' do
    before { sign_in_as(admin) }

    it 'lists recent audits' do
      audit
      get :index, format: :json
      audits = JSON.parse(response.body)['audits']
      expect(audits.first).to include('id' => audit.id, 'article_title' => 'Acme',
                                      'wiki' => 'en.wikipedia.org', 'requester' => admin.username)
    end

    it 'renders the React shell' do
      get :index
      expect(response.body).to include('react_root')
    end
  end

  describe 'GET #show' do
    let(:article) { nil }

    before do
      sign_in_as(admin)
      allow(ArticleAuditing::RenderedArticle).to receive(:fetch).and_return(article)
    end

    it 'returns the latest result for each check' do
      audit.check_results.create!(check_key: 'tone', status: 'failed', error: 'boom')
      audit.check_results.create!(check_key: 'tone', status: 'succeeded',
                                  findings: [{ 'title' => 'Peacock' }],
                                  usage: { 'input_tokens' => 3 })
      get :show, params: { id: audit.id }, format: :json
      body = JSON.parse(response.body)
      expect(body['audit']).to include('id' => audit.id, 'status' => 'queued')
      expect(body['check_results'].size).to eq(1)
      result = body['check_results'].first
      expect(result).to include('status' => 'succeeded', 'run_count' => 2)
      expect(result['findings']).to eq([{ 'title' => 'Peacock', 'id' => "#{result['id']}-0",
                                          'anchor' => nil }])
      expect(body['article_html']).to be_nil
    end

    context 'when the revision can be fetched' do
      let(:article) { { html: '<p>Acme is a world-class company.</p>', wikitext: '' } }

      it 'returns the article with each finding marked where it applies' do
        audit.check_results.create!(check_key: 'tone', status: 'succeeded', findings: [
                                      { 'severity' => 'should_fix', 'title' => 'Peacock',
                                        'location' => { 'quote' => 'world-class' } }
                                    ])
        get :show, params: { id: audit.id }, format: :json
        body = JSON.parse(response.body)
        finding = body['check_results'].first['findings'].first
        expect(finding['anchor']).to eq('text')
        expect(body['article_html']).to include(
          %(<mark class="aa-mark aa-mark--should_fix" data-findings="#{finding['id']}">)
        )
        expect(ArticleAuditing::RenderedArticle).to have_received(:fetch)
          .with(audit.wiki, audit.mw_rev_id).once
      end
    end

    it 'marks the results an LLM produced' do
      { 'tone' => 'anthropic:claude-opus-5-5', 'sourcing.reference_list' => 'deterministic',
        'external.ai_detection' => 'pangram:pangram_v3' }.each do |check_key, engine|
        audit.check_results.create!(check_key:, engine:, status: 'succeeded')
      end
      get :show, params: { id: audit.id }, format: :json
      llm = JSON.parse(response.body)['check_results'].to_h { |r| [r['check_key'], r['llm']] }
      expect(llm).to eq('tone' => true, 'sourcing.reference_list' => false,
                        'external.ai_detection' => false)
    end
  end

  describe 'POST #create' do
    before { sign_in_as(admin) }

    it 'creates and queues an audit' do
      allow(ArticleAuditWorker).to receive(:run)
      post :create, params: { url: 'https://en.wikipedia.org/w/index.php?oldid=555' }, format: :json
      expect(response).to have_http_status(:created)
      expect(ArticleAudit.find(JSON.parse(response.body)['id']).mw_rev_id).to eq(555)
    end

    it 'returns an error for a bad URL' do
      post :create, params: { url: 'not a url' }, format: :json
      expect(response).to have_http_status(:unprocessable_content)
      expect(JSON.parse(response.body)['error']).to eq('invalid_url')
    end
  end

  describe 'POST #rerun_check' do
    before { sign_in_as(admin) }

    it 'queues a re-run of a known check' do
      allow(ArticleAuditCheckWorker).to receive(:rerun)
      post :rerun_check, params: { id: audit.id, check_key: 'tone' }, format: :json
      expect(response).to have_http_status(:accepted)
      expect(ArticleAuditCheckWorker).to have_received(:rerun).with(audit, 'tone')
    end

    it 'rejects an unknown check' do
      post :rerun_check, params: { id: audit.id, check_key: 'nope' }, format: :json
      expect(response).to have_http_status(:unprocessable_content)
    end
  end
end
