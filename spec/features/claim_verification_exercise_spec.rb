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

  # The exercise's step headings, composed the way the app composes them, so
  # these pin the numbers rather than restating the copy. The two pre-form steps
  # name their copy directly; the form's steps keep theirs under `form`.
  def step_heading(number, name_key)
    I18n.t('claim_verification.step_heading',
           number:, name: I18n.t("claim_verification.#{name_key}"))
  end

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

  it 'goes picker -> viewer -> take -> taken claim -> submitted form, with no page reloads' do
    # A timeline block assigning the exercise module, to verify that
    # submitting marks it complete on the timeline without a reload.
    TrainingModule.load_all
    exercise_module = TrainingModule.find_by(slug: 'fact-verification-exercise')
    week = create(:week, course:)
    create(:block, week:, due_date: course.start + 1.week,
                   training_module_ids: [exercise_module.id])

    visit "/courses/#{course.slug}/verify_claim"

    # The article picker is the first sub-view (no claim taken yet). The exercise
    # names itself before it says what to do, so the title is the page's h1 and
    # step 1 an h2 — the level every other step of the exercise uses.
    expect(page).to have_css('h2', text: step_heading(1, 'step_select_article'), wait: 20)
    expect(page).to have_css('h1', text: I18n.t('claim_verification.exercise_heading'))
    expect(page).to have_content(I18n.t('claim_verification.select_article_instructions'))
    # Mark the window so we can prove the rest of the flow never triggers a reload.
    page.execute_script('window.cvSameDocument = true;')
    # Each article tile is itself the opener for its in-place viewer (a button,
    # not a link).
    click_on 'Sea otter'

    # Choosing a claim is step 2, and the viewer's banner says so: the numbering
    # runs on from the picker into the server-numbered form steps below.
    expect(page).to have_css('.cv-pick-banner__heading',
                             text: step_heading(2, 'step_select_claim'), wait: 20)

    # The viewer renders the flagged revision annotated with its harvested claims;
    # clicking the highlighted claim sentence opens the in-viewer panel.
    find('.parsed-article .cv-claim', wait: 20).click
    within '.cv-selection-panel' do
      expect(page).to have_content(sentence)
      click_button I18n.t('claim_verification.select_claim')
    end

    # Taking the claim transitions to the taken-claim view in place, where the
    # verification form lives.
    expect(page).to have_content(I18n.t('claim_verification.your_selected_claim'), wait: 10)
    expect(page).to have_content(sentence)
    expect(page.evaluate_script('window.cvSameDocument')).to be(true)

    assignment = VerificationClaimAssignment.find_by(user: student, course:)
    expect(assignment.verification_claim.sentence).to eq(sentence)

    # The source-evaluation step comes first, judged from the citation alone. It
    # is step 3: the form's numbering (config's `first_step_number`) picks up
    # where the two pre-form steps left off.
    expect(page).to have_content(step_heading(3, 'form.step_evaluate_source'))
    # Step instructions render as Markdown, so a URL in the operator copy is a
    # link out of the exercise rather than inert text.
    policy_link = find('.cv-form__step-instructions a', match: :first)
    expect(policy_link[:href]).to include('Wikipedia:Reliable_sources')
    expect(policy_link[:target]).to eq('_blank')
    choose I18n.t('claim_verification.form.source_appropriate_options.appropriate')
    choose I18n.t('claim_verification.form.meets_rs_policy_options.context_dependent')

    # Then finding the source. The closing comments field has no business being
    # asked before the student has said whether they even got the source, so it
    # waits on that answer too — and then arrives whichever way they answered.
    expect(page).to have_content(I18n.t('claim_verification.form.step_find_source'))
    expect(page).to have_no_field(I18n.t('claim_verification.form.other_comments_label'))
    choose I18n.t('claim_verification.form.source_access_options.accessed')
    expect(page).to have_content(I18n.t('claim_verification.form.step_verify'))
    expect(page).to have_field(I18n.t('claim_verification.form.other_comments_label'))
    choose I18n.t('claim_verification.form.verdict_options.partial_support')
    fill_in I18n.t('claim_verification.form.claim_location_label'), with: 'p. 44'
    click_button I18n.t('claim_verification.form.submit')

    # Submission swaps the form for the summary of their answers. Switching
    # claims stays possible — responses are keyed per claim, so another claim
    # would simply start a fresh form.
    expect(page).to have_content(
      I18n.t('claim_verification.form.verdict_options.partial_support'), wait: 10
    )
    expect(page).to have_no_button(I18n.t('claim_verification.form.submit'))
    expect(page).to have_content(I18n.t('claim_verification.choose_different_claim'))

    # Browsing the other candidates must not cost them the claim they answered
    # for: the picker offers a way back, and returning restores their answers
    # rather than a blank form.
    click_button I18n.t('claim_verification.choose_different_claim')
    expect(page).to have_content(I18n.t('claim_verification.step_select_article'), wait: 10)
    click_button "← #{I18n.t('claim_verification.back_to_claim')}"
    expect(page).to have_content(I18n.t('claim_verification.your_selected_claim'), wait: 10)
    expect(page).to have_content(
      I18n.t('claim_verification.form.verdict_options.partial_support')
    )

    response = VerificationClaimResponse.find_by(user: student, course:)
    expect(response.answer('source_appropriate')).to eq('appropriate')
    expect(response.answer('meets_rs_policy')).to eq('context_dependent')
    expect(response.answer('verdict')).to eq('partial_support')
    expect(response.answer('claim_location')).to eq('p. 44')
    expect(response.verification_claim).to eq(assignment.verification_claim)

    # Navigating (client-side) back to the timeline shows the exercise as
    # complete right away — submitting refreshed the timeline data.
    click_link 'Timeline'
    expect(page).to have_content('Status: Complete!', wait: 10)
    expect(page.evaluate_script('window.cvSameDocument')).to be(true)
  end

  it 'shows a student their own submitted response in a popover on the students tab' do
    TrainingModule.load_all
    exercise_module = TrainingModule.find_by(slug: 'fact-verification-exercise')
    week = create(:week, course:)
    create(:block, week:, due_date: course.start + 1.week,
                   training_module_ids: [exercise_module.id])
    claim = VerificationClaim.find_by(sentence:)
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
    VerificationClaimResponse.create!(
      user: student, course:, verification_claim: claim,
      answers: {
        'source_appropriate' => 'appropriate',
        'meets_rs_policy' => 'generally_reliable',
        'source_access' => 'accessed',
        'verdict' => 'partial_support',
        'claim_location' => 'chapter 3',
        'verification_notes' => 'The chapter describes tool use at length, but the shellfish ' \
                                'detail only appears in a figure caption, which took a while ' \
                                'to find because the scanned copy has no searchable text.',
        'other_comments' => 'Reference: https://example.com/very/long/unbroken/path/to/a/' \
                            'scanned/document/section-3-2-1#page=44&highlight=sea-otters'
      }
    )
    tmu = TrainingModulesUsers.create!(user: student, training_module_id: exercise_module.id,
                                       completed_at: Time.zone.now)
    tmu.mark_completion(true, course.id)
    tmu.save!

    # The student detail view's exercise listing: expanding the exercise row's
    # drawer reveals the submitted response as a popover — no navigation.
    details_path = "/courses/#{course.slug}/students/articles/Otterfan"
    visit details_path
    find('tr.students-exercise', wait: 20).click
    click_button I18n.t('claim_verification.form.submitted_heading'), wait: 10
    within '.cv-response-pop' do
      expect(page).to have_content(sentence)
      expect(page).to have_content(
        I18n.t('claim_verification.form.verdict_options.partial_support')
      )
      expect(page).to have_content('chapter 3')
    end
    # Long free-text answers wrap inside the popover rather than pushing it
    # off the right edge of the screen.
    fits_viewport = page.evaluate_script(
      'document.querySelector(".cv-response-pop .pop").getBoundingClientRect().right' \
      ' <= window.innerWidth'
    )
    expect(fits_viewport).to be(true)
    expect(page).to have_current_path(details_path, ignore_query: true)
  end

  it 'gives an instructor the exercise itself, and the submissions on their own page' do
    instructor = create(:user, username: 'Prof', onboarded: true)
    create(:courses_user, course:, user: instructor,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    claim = VerificationClaim.find_by(sentence:)
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)
    VerificationClaimResponse.create!(
      user: student, course:, verification_claim: claim,
      answers: { 'source_appropriate' => 'appropriate',
                 'meets_rs_policy' => 'generally_reliable',
                 'source_access' => 'accessed', 'verdict' => 'contradicted',
                 'other_comments' => 'The source says the opposite.' }
    )
    # A second student who has taken a claim but not submitted.
    slow_student = create(:user, username: 'Slowpoke', onboarded: true)
    create(:courses_user, course:, user: slow_student, role: CoursesUsers::Roles::STUDENT_ROLE)
    VerificationClaimAssignment.create!(user: slow_student, course:, verification_claim: claim)
    # courses#show verifies an instructor's OAuth edit credentials.
    stub_token_request
    login_as instructor

    # /verify_claim is the exercise for instructors too.
    visit "/courses/#{course.slug}/verify_claim"
    expect(page).to have_content(I18n.t('claim_verification.step_select_article'), wait: 20)

    # The submissions live on their own page (a full-page load must work too).
    visit "/courses/#{course.slug}/verify_claim/responses"
    expect(page).to have_content(I18n.t('claim_verification.responses.heading'), wait: 20)
    expect(page).to have_content('Otterfan')
    expect(page).to have_content(sentence)
    expect(page).to have_content(I18n.t('claim_verification.form.verdict_options.contradicted'))
    expect(page).to have_content('The source says the opposite.')
    expect(page).to have_content(I18n.t('claim_verification.responses.pending_heading'))
    expect(page).to have_content('Slowpoke')

    # The ?student= deep link (used from the student detail view) narrows the
    # page to one student; the return link restores the full list.
    visit "/courses/#{course.slug}/verify_claim/responses?student=Otterfan"
    expect(page).to have_content('Otterfan', wait: 20)
    expect(page).to have_no_content('Slowpoke')
    click_link "← #{I18n.t('claim_verification.responses.heading')}"
    expect(page).to have_content('Slowpoke', wait: 10)
  end

  # Arriving on a shared ?showArticle= link forces the picker into view even when
  # the student already has a claim, so the way back has to work from there too —
  # and the open article id lives in the URL, not in component state.
  it 'lets a student with a claim return from a ?showArticle= deep link' do
    claim = VerificationClaim.find_by(sentence:)
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)

    visit "/courses/#{course.slug}/verify_claim?showArticle=#{article.id}"
    expect(page).to have_css('.article-viewer', wait: 20)
    find('.article-viewer-button.icon-close', match: :first).click

    click_button "← #{I18n.t('claim_verification.back_to_claim')}"
    expect(page).to have_content(I18n.t('claim_verification.your_selected_claim'), wait: 10)
    expect(page).to have_content(sentence)
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
    expect(page).to have_content(I18n.t('claim_verification.step_select_article'), wait: 20)
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
