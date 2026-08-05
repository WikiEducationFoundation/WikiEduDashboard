# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

# Screenshot harness for the Fall 2026 research-experiment opt-in UI, used to
# build the PR description. Gated on ENV['SCREENSHOT'] so it contributes nothing
# to the regular suite:
#
#   SCREENSHOT=pr bundle exec rspec spec/features/experiment_opt_in_screenshots_spec.rb
#
# Output lands in tmp/screenshots/$SCREENSHOT/, which is where bin/open-pr looks
# for the images referenced by tmp/pr_description.md.
describe 'Research experiment opt-in screenshots', type: :feature, js: true,
         if: ENV['SCREENSHOT'] do
  let(:screenshot_dir) { Rails.root.join('tmp', 'screenshots', ENV.fetch('SCREENSHOT')) }
  let(:experiment) { Fall2026ResearchExperiment.new }
  let(:instructor) do
    create(:user, username: 'Alice Nakamura', permissions: User::Permissions::INSTRUCTOR)
  end
  let(:student) { create(:user, username: 'Jordan Reyes') }
  let(:course) do
    create(:course, title: 'Environmental Policy',
                    school: 'Northwestern University',
                    term: 'Fall 2026',
                    slug: 'Northwestern_University/Environmental_Policy_(Fall_2026)',
                    submitted: false,
                    passcode: 'passcode',
                    start: Date.new(2026, 9, 1),
                    end: Date.new(2026, 12, 15),
                    timeline_start: Date.new(2026, 9, 1),
                    timeline_end: Date.new(2026, 12, 15))
  end

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1100)
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    allow(Features).to receive(:fall_2026_research_student_optin?).and_return(true)
  end

  after { logout }

  # Clip a screenshot to one element. Modals and wizard panels are often taller
  # than the viewport (and headless Chrome caps window height), so emulate a
  # viewport tall enough for the whole element to lay out, clip to its box, then
  # clear the override so later navigation still works.
  def shoot_element(selector, name)
    sleep 0.4
    cdp = page.driver.browser
    height = page.evaluate_script("document.querySelector('#{selector}').scrollHeight").to_i
    cdp.execute_cdp('Emulation.setDeviceMetricsOverride',
                    width: 1440, height: height + 240, deviceScaleFactor: 1, mobile: false)
    sleep 0.6
    rect = page.evaluate_script(<<~JS)
      (function () {
        var r = document.querySelector('#{selector}').getBoundingClientRect();
        return { x: r.left, y: r.top, width: r.width, height: r.height };
      })()
    JS
    shot = cdp.execute_cdp('Page.captureScreenshot', format: 'png',
                                                     clip: { x: rect['x'], y: rect['y'],
                                                             width: rect['width'],
                                                             height: rect['height'], scale: 1 })
    File.binwrite(screenshot_dir.join("#{name}.png"), Base64.decode64(shot['data']))
    cdp.execute_cdp('Emulation.clearDeviceMetricsOverride')
    sleep 0.3
  end

  # Enrol the student in a course whose instructor has already opted it in.
  def join_participating_course
    create(:tag, course:, tag: experiment.opted_in_tag)
    courses_user = create(:courses_user, user: student, course:,
                                         role: CoursesUsers::Roles::STUDENT_ROLE)
    login_as(student, scope: :user)
    courses_user
  end

  def stub_common_js(content)
    allow_any_instance_of(WikiApi).to receive(:get_page_content).and_return(content)
  end

  it 'captures the instructor wizard opt-in panel' do
    TrainingModule.load_all
    stub_oauth_edit
    create(:courses_user, user: instructor, course:,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as(instructor, scope: :user)

    visit "/courses/#{course.slug}/timeline/wizard"
    expect(page).to have_css('.wizard__panel.active')
    sleep 2

    # Course-dates panel, then pick the research-write assignment type. The
    # research-study panel is the first researchwrite panel after that. Mirrors
    # go_through_course_dates_and_timeline_dates in course_creation_spec.rb.
    find('span[title="Wednesday"]', match: :first).click
    within('.wizard__panel.active') do
      expect(page).not_to have_css('button.dark[disabled]')
    end
    click_button 'Next'
    sleep 1
    find('.wizard__option', match: :first).find('button', match: :first).click
    click_button 'Next'
    sleep 1

    expect(page).to have_content('research experiment')
    shoot_element('.wizard__panel.active', '01_instructor_wizard_optin')
  end

  it 'captures the student consent modal' do
    join_participating_course
    visit "/courses/#{course.slug}"
    expect(page).to have_css('.experiment-opt-in__panel')
    expect(page).to have_button('I consent')
    shoot_element('.experiment-opt-in__panel', '02_student_consent_modal')
  end

  it 'captures the install step, and the unverified state after a re-check' do
    join_participating_course
    stub_common_js ''
    visit "/courses/#{course.slug}"
    expect(page).to have_css('.experiment-opt-in__panel')

    click_button 'I consent'
    expect(page).to have_css('.experiment-opt-in__snippet')
    shoot_element('.experiment-opt-in__panel', '03_student_install')

    # common.js still lacks the line, so the re-check reports it as missing.
    click_button 'Verify experiment script'
    expect(page).to have_css('.experiment-opt-in__not-found')
    shoot_element('.experiment-opt-in__panel', '04_student_install_not_found')
  end
end
