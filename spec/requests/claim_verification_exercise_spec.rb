# frozen_string_literal: true

require 'rails_helper'

# The exercise UI is the course SPA (served by courses#show); this controller
# only provides the flow's JSON and the slug-less entry funnel. These specs cover
# those: state (pool-backed tiles), annotated_article (the flagged revision with
# its harvested claims tagged), take (assigning a pool claim) and entry.
describe 'Claim verification exercise', type: :request do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki)
  end
  let(:student) { create(:user, username: 'Otterfan', onboarded: true) }
  let(:article) do
    create(:article, wiki:, title: 'Sea otter', namespace: Article::Namespaces::MAINSPACE)
  end
  let(:flagged_rev) { 777 }

  # A claim pre-harvested from a same-subject course's flagged revision.
  let!(:pool_claim) do
    source_course = create(:course, slug: 'Old/Eco_2019', subject: 'Ecology')
    alert = create(:ai_edit_alert, course: source_course, article:, revision_id: flagged_rev,
                                   details: { article_title: 'Sea otter' })
    VerificationClaim.create!(wiki:, article:, article_title: 'Sea_otter', mw_rev_id: flagged_rev,
                              sentence: 'Sea otters use rocks as tools.', ref_id: 'cite_note-1',
                              source_url: 'https://example.com/otters', cite_text: 'Riedman 1990',
                              subject: 'Ecology', source_course:, alert:)
  end

  let(:revision_html) do
    <<~HTML
      <p>Sea otters use rocks as tools.<sup class="reference"><a href="#cite_note-1">[1]</a></sup></p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Riedman 1990</a></cite></span></li></ol>
    HTML
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    login_as student
  end

  describe 'GET state' do
    it 'lists the (article, flagged-revision) tiles from the pool when no claim is taken' do
      get "/courses/#{course.slug}/verify_claim/state"
      body = response.parsed_body
      expect(body['assignment']).to be_nil
      expect(body['articles'].first)
        .to include('id' => article.id, 'mw_rev_id' => flagged_rev, 'title' => 'Sea otter',
                    'language' => 'en', 'project' => 'wikipedia')
    end

    it 'returns the taken claim when one is taken' do
      VerificationClaimAssignment.create!(user: student, course:, verification_claim: pool_claim)
      get "/courses/#{course.slug}/verify_claim/state"
      assignment = response.parsed_body['assignment']
      expect(assignment['claim']['sentence']).to eq('Sea otters use rocks as tools.')
      expect(assignment['claim']['source_url']).to eq('https://example.com/otters')
      expect(response.parsed_body['response']).to be_nil
    end

    it 'returns the submitted response alongside the taken claim' do
      VerificationClaimAssignment.create!(user: student, course:, verification_claim: pool_claim)
      VerificationClaimResponse.create!(user: student, course:, verification_claim: pool_claim,
                                        source_access: 'accessed', verdict: 'full_support')
      get "/courses/#{course.slug}/verify_claim/state"
      expect(response.parsed_body['response']['verdict']).to eq('full_support')
    end

    it 'is open to any signed-in user, even one not enrolled in the course' do
      outsider = create(:user, username: 'Outsider', onboarded: true)
      login_as outsider
      get "/courses/#{course.slug}/verify_claim/state"
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['articles']).to be_present
    end
  end

  describe 'GET annotated_article' do
    before do
      allow(GetRevisionHtmlWithCitations).to receive(:new)
        .and_return(instance_double(GetRevisionHtmlWithCitations, html: revision_html))
    end

    it "serves the flagged revision's HTML with its harvested claims tagged" do
      get "/courses/#{course.slug}/verify_claim/annotated_article",
          params: { article_id: article.id, mw_rev_id: flagged_rev }
      body = response.parsed_body
      expect(body['mw_rev_id']).to eq(flagged_rev)
      expect(body['html']).to include('cv-claim')
      expect(body['html']).to include(%(data-claim-id="#{pool_claim.id}"))
    end
  end

  describe 'POST take' do
    it 'assigns the chosen pool claim and returns it as the assignment' do
      post "/courses/#{course.slug}/verify_claim/take",
           params: { article_id: article.id, verification_claim_id: pool_claim.id }
      assignment = response.parsed_body['assignment']
      expect(assignment['claim']['sentence']).to eq('Sea otters use rocks as tools.')
      expect(VerificationClaimAssignment.find_by(user: student, course:).verification_claim)
        .to eq(pool_claim)
    end

    it 'forbids taking a claim in a course the user is not enrolled in' do
      outsider = create(:user, username: 'Outsider', onboarded: true)
      login_as outsider
      post "/courses/#{course.slug}/verify_claim/take",
           params: { article_id: article.id, verification_claim_id: pool_claim.id }
      expect(response).to have_http_status(:forbidden)
      expect(VerificationClaimAssignment.where(user: outsider)).to be_empty
    end

    it 'lets more than one student take the same claim (claims are not exclusive)' do
      post "/courses/#{course.slug}/verify_claim/take",
           params: { article_id: article.id, verification_claim_id: pool_claim.id }
      other = create(:user, username: 'Otterfan2', onboarded: true)
      create(:courses_user, course:, user: other, role: CoursesUsers::Roles::STUDENT_ROLE)
      login_as other
      post "/courses/#{course.slug}/verify_claim/take",
           params: { article_id: article.id, verification_claim_id: pool_claim.id }
      expect(VerificationClaimAssignment.where(verification_claim: pool_claim).count).to eq(2)
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
