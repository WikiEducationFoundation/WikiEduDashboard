# frozen_string_literal: true

require 'rails_helper'

# Screenshot harness for the fact-verification exercise, used to build
# before/after images for PR descriptions. Gated on ENV['SCREENSHOT'] so it
# contributes nothing to the regular suite:
#
#   SCREENSHOT=after bundle exec rspec spec/features/claim_verification_screenshots_spec.rb
#
# Output lands in tmp/screenshots/$SCREENSHOT/, which is where bin/pr-screenshots
# and bin/open-pr look for the images referenced by tmp/pr_description.md.
#
# The student's claim is seeded as already taken, so the verification form is
# reached without going through the article viewer (which fetches the real
# revision from en.wikipedia.org). Only the landing example shows the picker,
# and it never opens a tile, so this spec needs no network access.
describe 'Fact verification exercise screenshots', type: :feature, js: true,
         if: ENV['SCREENSHOT'] do
  let(:screenshot_dir) { Rails.root.join('tmp', 'screenshots', ENV.fetch('SCREENSHOT')) }
  let(:wiki) { Wiki.get_or_create(language: 'en', project: 'wikipedia') }
  let(:course) do
    create(:course, title: 'Marine Ecology',
                    school: 'Coastal State University',
                    term: 'Fall 2026',
                    slug: 'Coastal_State_University/Marine_Ecology_(Fall_2026)',
                    subject: 'Ecology',
                    home_wiki: wiki,
                    start: Date.new(2026, 9, 1),
                    end: Date.new(2026, 12, 15))
  end
  let(:student) { create(:user, username: 'Jordan Reyes', onboarded: true) }
  let(:source_course) { create(:course, slug: 'Old/Ecology_2025', subject: 'Ecology') }

  # The claim the student has taken: a plausible sentence with a real-looking
  # citation, so the claim and source cards read like the production exercise.
  let(:sentence) do
    'Sea otters use rocks as tools to break open hard-shelled prey such as ' \
      'clams and sea urchins, a behavior documented in over 90% of foraging dives.'
  end
  let(:cite_text) do
    'Riedman, M. L.; Estes, J. A. (1990). The Sea Otter (Enhydra lutris): ' \
      'Behavior, Ecology, and Natural History. Biological Report 90(14). ' \
      'U.S. Fish and Wildlife Service. pp. 41–47.'
  end
  let(:context) do
    'Sea otters are one of the few mammal species known to use tools. ' \
      "#{sentence} They often keep a favored rock in a loose pouch of skin under " \
      'the forearm between dives.'
  end

  # A pool claim for one (article, flagged revision), so the picker has tiles.
  def seed_claim(title:, mw_page_id:, mw_rev_id:, timestamp:, sentence:, cite_text:, source_url:,
                 context: nil)
    article = create(:article, wiki:, title:, mw_page_id:,
                               namespace: Article::Namespaces::MAINSPACE)
    alert = create(:ai_edit_alert, course: source_course, article:, revision_id: mw_rev_id,
                                   details: { article_title: title.tr('_', ' ') })
    VerificationClaim.create!(wiki:, article:, article_title: title, mw_rev_id:,
                              mw_rev_timestamp: timestamp, sentence:, context:,
                              ref_id: 'cite_note-1', cite_text:, source_url:,
                              subject: 'Ecology', source_course:, alert:)
  end

  let!(:claim) do
    seed_claim(title: 'Sea_otter', mw_page_id: 567_471, mw_rev_id: 1_291_004_512,
               timestamp: Time.zone.local(2026, 4, 27, 15, 12), sentence:, cite_text:, context:,
               source_url: 'https://pubs.usgs.gov/publication/5200103')
  end

  before do
    # A few more candidates, so the picker reads as a real grid of choices.
    seed_claim(title: 'Kelp_forest', mw_page_id: 1_113_884, mw_rev_id: 1_290_887_331,
               timestamp: Time.zone.local(2026, 4, 22, 9, 40),
               sentence: 'Kelp forests sequester an estimated 4.9 megatons of carbon annually.',
               cite_text: 'Filbee-Dexter, K.; Wernberg, T. (2020). "Substantial blue carbon in ' \
                          'overlooked Australian kelp forests". Scientific Reports 10: 12341.',
               source_url: 'https://doi.org/10.1038/s41598-020-69258-7')
    seed_claim(title: 'Purple_sea_urchin', mw_page_id: 1_935_205, mw_rev_id: 1_289_402_118,
               timestamp: Time.zone.local(2026, 4, 3, 18, 5),
               sentence: 'Purple sea urchin populations increased sixtyfold along the northern ' \
                         'California coast between 2014 and 2019.',
               cite_text: 'Rogers-Bennett, L.; Catton, C. A. (2019). "Marine heat wave and ' \
                          'multiple stressors tip bull kelp forest to sea urchin barrens". ' \
                          'Scientific Reports 9: 15050.',
               source_url: 'https://doi.org/10.1038/s41598-019-51114-y')
    seed_claim(title: 'Giant_kelp', mw_page_id: 346_812, mw_rev_id: 1_288_113_907,
               timestamp: Time.zone.local(2026, 3, 19, 11, 27),
               sentence: 'Giant kelp can grow up to 60 centimetres per day under ideal conditions.',
               cite_text: 'Schiel, D. R.; Foster, M. S. (2015). The Biology and Ecology of Giant ' \
                          'Kelp Forests. University of California Press.',
               source_url: nil)

    course.campaigns << Campaign.first
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)

    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1100)
    login_as(student, scope: :user)
  end

  after { logout }

  # Clip a screenshot to one element, found by a JavaScript expression. Form
  # steps and the whole exercise page are taller than the viewport (and
  # headless Chrome caps window height), so emulate a viewport tall enough for
  # the whole document to lay out with no scrolling, clip to the element's box
  # in document coordinates, then clear the override so later steps still work.
  def shoot_element(js_element, name)
    sleep 0.4
    cdp = page.driver.browser
    height = page.evaluate_script('document.documentElement.scrollHeight').to_i
    cdp.execute_cdp('Emulation.setDeviceMetricsOverride',
                    width: 1440, height: height + 240, deviceScaleFactor: 1, mobile: false)
    sleep 0.6
    rect = page.evaluate_script(<<~JS)
      (function () {
        var r = (#{js_element}).getBoundingClientRect();
        return { x: Math.floor(r.left + window.scrollX), y: Math.floor(r.top + window.scrollY),
                 width: Math.ceil(r.width), height: Math.ceil(r.height) + 4 };
      })()
    JS
    shot = cdp.execute_cdp('Page.captureScreenshot', format: 'png', captureBeyondViewport: true,
                                                     clip: { x: rect['x'], y: rect['y'],
                                                             width: rect['width'],
                                                             height: rect['height'], scale: 1 })
    File.binwrite(screenshot_dir.join("#{name}.png"), Base64.decode64(shot['data']))
    cdp.execute_cdp('Emulation.clearDeviceMetricsOverride')
    sleep 0.3
  end

  # The n-th (0-based) step card of the verification form.
  def form_step(index)
    "document.querySelectorAll('.cv-form__step')[#{index}]"
  end

  it 'captures the landing page: the introduction and the article picker' do
    visit "/courses/#{course.slug}/verify_claim"
    expect(page).to have_css('h1', text: I18n.t('claim_verification.exercise_heading'), wait: 20)
    expect(page).to have_content('Sea otter')
    shoot_element("document.querySelector('.claim-verification-exercise')", '01_landing_intro')
  end

  it 'captures the taken claim and each step of the verification form' do
    VerificationClaimAssignment.create!(user: student, course:, verification_claim: claim)

    visit "/courses/#{course.slug}/verify_claim"
    expect(page).to have_content(I18n.t('claim_verification.your_selected_claim'), wait: 20)
    expect(page).to have_content(I18n.t('claim_verification.form.step_find_source'))

    # Step 3 answered, step 4 still open: the whole page as the student sees it
    # while working down the form.
    choose I18n.t('claim_verification.form.source_appropriate_options.appropriate')
    choose I18n.t('claim_verification.form.meets_rs_policy_options.generally_reliable')
    shoot_element("document.querySelector('.claim-verification-exercise')",
                  '02_taken_claim_form')
    shoot_element(form_step(1), '03_step_4_find_source')

    # Saying they couldn't get the source brings up the prompt to choose
    # another claim instead.
    choose I18n.t('claim_verification.form.source_access_options.nonexistent')
    expect(page).to have_css('.cv-form__prompt')
    shoot_element(form_step(1), '03b_step_4_no_source')

    # Saying they got the source opens the verify step.
    choose I18n.t('claim_verification.form.source_access_options.accessed')
    expect(page).to have_content(I18n.t('claim_verification.form.step_verify'))
    shoot_element(form_step(2), '04_step_5_verify')

    choose I18n.t('claim_verification.form.verdict_options.full_support')
    fill_in I18n.t('claim_verification.form.claim_location_label'), with: 'p. 44, second paragraph'
    click_button I18n.t('claim_verification.form.submit')
    # The summary replaces the form (its heading is uppercased by CSS, so match
    # on the section rather than its text).
    expect(page).to have_css('.claim-verification-exercise__response', wait: 10)
    shoot_element("document.querySelector('.claim-verification-exercise__response')",
                  '05_submitted_summary')
  end
end
