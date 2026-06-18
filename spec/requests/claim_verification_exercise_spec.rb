# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

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

  it 'offers relevant prior-course articles when no claim is taken' do
    get "/courses/#{course.slug}/verify_claim"
    expect(response.body).to include(article.title)
    expect(response.body).to include("article_id=#{article.id}")
  end

  it 'mounts the claim-highlighting article viewer for a chosen article' do
    get "/courses/#{course.slug}/verify_claim", params: { article_id: article.id }
    expect(response.body).to include("id='claim-verification-viewer'")
    expect(response.body).to include("data-article-id='#{article.id}'")
    expect(response.body).to include("data-course-slug='#{course.slug}'")
  end

  it 'serves the annotated article HTML as JSON for the in-viewer picker' do
    stub_article_harvest
    get "/courses/#{course.slug}/verify_claim/annotated_article",
        params: { article_id: article.id }
    body = response.parsed_body
    expect(body['mw_rev_id']).to eq(555)
    expect(body['html']).to include('cv-claim')
    expect(body['html']).to include('Sea otters use rocks as tools.')
  end

  it "shows a chosen claim's source and a take action" do
    stub_article_harvest
    get "/courses/#{course.slug}/verify_claim",
        params: { article_id: article.id, sentence: 'Sea otters use rocks as tools.' }
    expect(response.body).to include('https://example.com/otters')
    expect(response.body).to include("#{course.slug}/verify_claim/take")
  end

  it 'takes a chosen claim and then shows it as the assignment' do
    stub_article_harvest
    post "/courses/#{course.slug}/verify_claim/take",
         params: { article_id: article.id, ref_id: 'cite_note-1',
                   sentence: 'Sea otters use rocks as tools.' }
    expect(response).to redirect_to("/courses/#{course.slug}/verify_claim")
    assignment = VerificationClaimAssignment.find_by(user: student, course:)
    expect(assignment.verification_claim.sentence).to eq('Sea otters use rocks as tools.')

    get "/courses/#{course.slug}/verify_claim"
    expect(response.body).to include('Sea otters use rocks as tools.')
    expect(response.body).to include('https://example.com/otters')
  end

  it 'lets a student with a taken claim choose a different one' do
    taken = VerificationClaim.create!(wiki:, sentence: 'Previously taken claim.')
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: taken)
    get "/courses/#{course.slug}/verify_claim", params: { choose: 1 }
    expect(response.body).to include(article.title)          # the article picker
    expect(response.body).not_to include('Previously taken claim.')
  end

  context 'with the slug-less entry point' do
    it 'infers the sole course and offers its relevant articles' do
      get '/verify_claim'
      expect(response.body).to include(article.title)
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
