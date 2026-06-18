# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# The exercise UI is the course SPA (served by courses#show); this controller
# only provides the flow's JSON and the slug-less entry funnel. These specs
# cover those: state, annotated_article, take, and entry.
describe 'Claim verification exercise', type: :request do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki)
  end
  let(:student) { create(:user, username: 'Otterfan', onboarded: true) }
  let(:article) do
    create(:article, wiki:, title: 'Sea otter', namespace: Article::Namespaces::MAINSPACE)
  end

  let(:article_html) do
    <<~HTML
      <p>Sea otters use rocks as tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Riedman 1990</a></cite></span></li></ol>
    HTML
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    # A prior ended course in the same subject that worked on the article.
    prior = create(:course, slug: 'Old/Eco_2019', subject: 'Ecology',
                            start: 2.years.ago, end: 1.year.ago)
    create(:articles_course, course: prior, article:)
    login_as student
  end

  def stub_article_harvest
    allow(WikiApi::ArticleContent).to receive(:new)
      .and_return(instance_double(WikiApi::ArticleContent, latest_revision_id: 555))
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: article_html))
  end

  describe 'GET state' do
    it 'lists relevant prior-course articles when no claim is taken' do
      get "/courses/#{course.slug}/verify_claim/state"
      body = response.parsed_body
      expect(body['assignment']).to be_nil
      expect(body['articles'].first).to include('id' => article.id, 'title' => 'Sea otter')
      expect(body['articles'].first).to include('language' => 'en', 'project' => 'wikipedia')
    end

    it 'returns the taken claim and the sandbox handoff when one is taken' do
      claim = VerificationClaim.create!(wiki:, sentence: 'Otters use rocks.',
                                        source_url: 'https://example.com/o', ref_id: 'cite_note-1',
                                        article_title: 'Sea_otter', cite_text: 'Riedman 1990')
      VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
      get "/courses/#{course.slug}/verify_claim/state"
      assignment = response.parsed_body['assignment']
      expect(assignment['claim']['sentence']).to eq('Otters use rocks.')
      expect(assignment['claim']['source_url']).to eq('https://example.com/o')
      expect(assignment['sandbox_url']).to include('User:Otterfan/Claim_verification_exercise')
    end
  end

  describe 'GET annotated_article' do
    it 'serves the article HTML with its cited claims tagged' do
      stub_article_harvest
      get "/courses/#{course.slug}/verify_claim/annotated_article",
          params: { article_id: article.id }
      body = response.parsed_body
      expect(body['mw_rev_id']).to eq(555)
      expect(body['html']).to include('cv-claim')
      expect(body['html']).to include('Sea otters use rocks as tools.')
    end
  end

  describe 'POST take' do
    it 'persists the chosen claim and returns it as the assignment' do
      stub_article_harvest
      post "/courses/#{course.slug}/verify_claim/take",
           params: { article_id: article.id, ref_id: 'cite_note-1',
                     sentence: 'Sea otters use rocks as tools.' }
      assignment = response.parsed_body['assignment']
      expect(assignment['claim']['sentence']).to eq('Sea otters use rocks as tools.')
      expect(assignment['claim']['source_url']).to eq('https://example.com/otters')
      expect(VerificationClaimAssignment.find_by(user: student, course:)).to be_present
    end
  end

  describe 'GET entry (slug-less)' do
    it 'redirects to the inferred sole course exercise' do
      get '/verify_claim'
      expect(response).to redirect_to("/courses/#{course.slug}/verify_claim")
    end

    it 'shows a course picker when the student has several courses' do
      other = create(:course, slug: 'School/Other_2024', subject: 'History', home_wiki: wiki)
      create(:courses_user, course: other, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
      get '/verify_claim'
      expect(response.body).to include("/courses/#{course.slug}/verify_claim")
      expect(response.body).to include("/courses/#{other.slug}/verify_claim")
    end
  end
end
