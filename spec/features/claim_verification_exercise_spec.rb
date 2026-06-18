# frozen_string_literal: true

require 'rails_helper'
require_dependency "#{Rails.root}/lib/wiki_api/article_content"

# End-to-end of the claim-selection flow, now folded into the course SPA: the
# student goes picker -> article viewer -> take -> taken claim entirely
# client-side, with no page reloads. The article harvest (annotated_article and
# the take re-harvest) is stubbed for determinism; the viewer still fetches the
# real parsed article from en.wikipedia.org to resolve the title (its content is
# then replaced by our annotated HTML), so this spec needs network access, like
# the existing article_viewer_spec.
describe 'Claim verification exercise', type: :feature, js: true do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki,
                    start: 1.month.ago, end: 1.year.from_now)
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
    course.campaigns << Campaign.first
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
    # A prior ended course in the same subject that worked on the article.
    prior = create(:course, slug: 'Old/Eco_2019', subject: 'Ecology',
                            start: 2.years.ago, end: 1.year.ago)
    create(:articles_course, course: prior, article:)

    # Deterministic harvest for the annotated_article endpoint and the take.
    allow(WikiApi::ArticleContent).to receive(:new)
      .and_return(instance_double(WikiApi::ArticleContent, latest_revision_id: 555))
    allow(GetRevisionHtmlWithCitations).to receive(:new)
      .and_return(instance_double(GetRevisionHtmlWithCitations, html: article_html))

    login_as student
  end

  it 'goes picker -> viewer -> take -> taken claim with no page reloads' do
    visit "/courses/#{course.slug}/verify_claim"

    # The article picker is the first sub-view (no claim taken yet). Mark the
    # window so we can prove the rest of the flow never triggers a reload.
    expect(page).to have_content(I18n.t('claim_verification.choose_article'), wait: 20)
    page.execute_script('window.cvSameDocument = true;')
    click_link 'Sea otter'

    # The viewer renders the annotated article; clicking the highlighted claim
    # opens the in-viewer panel.
    find('.parsed-article sup.cv-claim', wait: 20).click
    within '.cv-selection-panel' do
      expect(page).to have_content(sentence)
      click_button I18n.t('claim_verification.select_claim')
    end

    # Taking the claim transitions to the taken-claim view in place.
    expect(page).to have_content(I18n.t('claim_verification.your_selected_claim'), wait: 10)
    expect(page).to have_content(sentence)
    expect(page.evaluate_script('window.cvSameDocument')).to be(true)

    assignment = VerificationClaimAssignment.find_by(user: student, course:)
    expect(assignment.verification_claim.sentence).to eq(sentence)
  end
end
