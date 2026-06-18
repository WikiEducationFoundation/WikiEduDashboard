# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# End-to-end of the claim-selection UX built on the ArticleViewer: the student
# opens an article, the viewer renders it with cited claims highlighted, they
# click a claim and take it on. The article's harvest (the annotated_article
# endpoint and the take re-harvest) is stubbed for determinism; the viewer still
# fetches the real parsed article from Wikipedia to resolve the title (its
# content is then replaced by our annotated HTML), so this spec needs network
# access to en.wikipedia.org — like the existing article_viewer_spec.
describe 'Claim verification exercise', type: :feature, js: true do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki)
  end
  let(:student) { create(:user, username: 'Otterfan', onboarded: true) }
  let(:article) do
    create(:article, wiki:, title: 'Sea_otter', mw_page_id: 41207,
                     namespace: Article::Namespaces::MAINSPACE)
  end
  let(:sentence) { 'Sea otters use rocks as tools to break open shellfish.' }

  let(:article_html) do
    <<~HTML
      <p>#{sentence}<sup class="reference"><a href="#cite_note-1">[1]</a></sup>
      They are a keystone species of the kelp forest ecosystem.</p>
      <ol class="references"><li id="cite_note-1"><span class="reference-text"><cite>
        <a class="external" href="https://example.com/otters">Riedman &amp; Estes 1990</a>
      </cite></span></li></ol>
    HTML
  end

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    # A prior ended course in the same subject that worked on the article, so it
    # is offered as a candidate.
    prior = create(:course, slug: 'Old/Eco_2019', subject: 'Ecology',
                            start: 2.years.ago, end: 1.year.ago)
    create(:articles_course, course: prior, article:)

    # Deterministic harvest for both the annotated_article endpoint and the take
    # re-harvest (the in-process server sees these stubs).
    allow(WikiApi::ArticleContent).to receive(:new)
      .and_return(instance_double(WikiApi::ArticleContent, latest_revision_id: 555))
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: article_html))

    login_as student
  end

  it 'highlights a cited claim, opens it in the viewer, and takes it on' do
    visit "/courses/#{course.slug}/verify_claim?article_id=#{article.id}"

    # The viewer opens on mount and renders the annotated article: the cited
    # claim's citation marker is highlighted (tagged cv-claim by the backend).
    marker = find('.parsed-article sup.cv-claim', wait: 20)
    expect(page).to have_content(sentence, wait: 10)

    # Clicking the highlighted claim opens the in-viewer selection panel.
    marker.click
    within '.cv-selection-panel' do
      expect(page).to have_content(sentence)
      expect(page).to have_content('Riedman & Estes 1990')
      expect(page).to have_link(I18n.t('claim_verification.source_url'),
                                href: 'https://example.com/otters')
      click_button I18n.t('claim_verification.select_claim')
    end

    # Taking the claim records it and returns to the exercise showing it.
    expect(page).to have_content(sentence, wait: 10)
    assignment = VerificationClaimAssignment.find_by(user: student, course:)
    expect(assignment.verification_claim.sentence).to eq(sentence)
  end
end
