# frozen_string_literal: true

require 'rails_helper'

# End-to-end of the claim-selection flow, folded into the course SPA: the student
# goes picker -> article viewer -> take -> taken claim entirely client-side, with
# no page reloads. Candidates come from the pre-harvested claim pool; the article
# opens at the AiEditAlert-flagged revision and the harvested claims are
# highlighted. The server-side annotation (annotated_article) is stubbed for
# determinism, but the viewer still fetches the real parsed revision from
# en.wikipedia.org to resolve the title (its content is then replaced by our
# annotated HTML), so this spec needs network access, like the article_viewer_spec.
# `flagged_rev` is a real, permanent Sea otter revision so that fetch resolves.
describe 'Claim verification exercise', type: :feature, js: true do
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, slug: 'School/Claims_2024', subject: 'Ecology', home_wiki: wiki,
                    start: 1.month.ago, end: 1.year.from_now)
  end
  let(:student) { create(:user, username: 'Otterfan', onboarded: true) }
  let(:article) do
    create(:article, wiki:, title: 'Sea_otter', mw_page_id: 567471,
                     namespace: Article::Namespaces::MAINSPACE)
  end
  let(:flagged_rev) { 2_998_441 } # the first revision of en:Sea otter
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

    # A claim pre-harvested from a same-subject course's flagged revision.
    source_course = create(:course, slug: 'Old/Eco_2019', subject: 'Ecology')
    alert = create(:ai_edit_alert, course: source_course, article:, revision_id: flagged_rev,
                                   details: { article_title: 'Sea otter' })
    VerificationClaim.create!(wiki:, article:, article_title: 'Sea_otter', mw_rev_id: flagged_rev,
                              sentence:, ref_id: 'cite_note-1', cite_text: 'Riedman & Estes 1990',
                              source_url: 'https://example.com/otters', subject: 'Ecology',
                              source_course:, alert:)

    # Deterministic server-side annotation of the flagged revision.
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
    # Each article tile is itself the opener for its in-place viewer (a button,
    # not a link).
    click_on 'Sea otter'

    # The viewer renders the flagged revision annotated with its harvested claims;
    # clicking the highlighted claim sentence opens the in-viewer panel.
    find('.parsed-article .cv-claim', wait: 20).click
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

  it 'deep-links straight into an open article via ?showArticle=' do
    visit "/courses/#{course.slug}/verify_claim?showArticle=#{article.id}"

    # The viewer opens on load from the permalink, with no tile click.
    expect(page).to have_css('.article-viewer', wait: 20)
    expect(page).to have_css('.parsed-article .cv-claim')
  end

  it 'tells a non-enrolled user they must enroll, and does not assign the claim' do
    outsider = create(:user, username: 'Interloper', onboarded: true)
    login_as outsider

    visit "/courses/#{course.slug}/verify_claim"
    expect(page).to have_content(I18n.t('claim_verification.choose_article'), wait: 20)
    click_on 'Sea otter'
    find('.parsed-article .cv-claim', wait: 20).click
    within '.cv-selection-panel' do
      click_button I18n.t('claim_verification.select_claim')
    end

    # The take is rejected (not enrolled): a notification banner explains why, and the
    # view stays on the selection flow rather than transitioning to the taken claim.
    expect(page).to have_content(I18n.t('claim_verification.take_not_enrolled'), wait: 10)
    expect(page).to have_no_content(I18n.t('claim_verification.your_selected_claim'))
    expect(VerificationClaimAssignment.find_by(user: outsider, course:)).to be_nil
  end
end
