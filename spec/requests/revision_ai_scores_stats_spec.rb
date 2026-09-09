# frozen_string_literal: true

require 'rails_helper'

# Covers the JSON the stats page graphs read. A failed detector check is stored as
# a production row with nil likelihoods, so the distributions must not carry it.
describe 'revision AI scores stats JSON', type: :request do
  let(:admin) { create(:admin) }
  let(:wiki) { Wiki.get_or_create(project: 'wikipedia', language: 'en') }
  let(:course) { create(:course) }
  let(:user) { create(:user) }
  let(:article) { create(:article, title: 'Hockey') }

  before { login_as admin }

  def json
    get '/revision_ai_scores_stats.json'
    JSON.parse(response.body)
  end

  it 'includes a scored production row in both distributions' do
    create(:revision_ai_score, revision_id: 1, wiki_id: wiki.id, course_id: course.id,
           user_id: user.id, article:, avg_ai_likelihood: 0.3, max_ai_likelihood: 0.4,
           check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN)

    expect(json['avg_likelihoods']).to eq([{ 'value' => 0.3 }])
    expect(json['max_likelihoods']).to eq([{ 'value' => 0.4 }])
  end

  it 'renders with no scored rows at all' do
    expect(json['avg_likelihoods']).to eq([])
    expect(json['historical_scores_by_namespace']).to eq([])
  end

  it 'omits a failed check, which has no likelihood to distribute' do
    create(:revision_ai_score, revision_id: 2, wiki_id: wiki.id, course_id: course.id,
           user_id: user.id, article:, avg_ai_likelihood: nil, max_ai_likelihood: nil,
           check_origin: RevisionAiScore::COURSE_UPDATE_ORIGIN,
           details: { 'error' => 'PangramApi::RequestError', 'message' => 'out of credit' })

    expect(json['avg_likelihoods']).to eq([])
    expect(json['max_likelihoods']).to eq([])
  end
end
