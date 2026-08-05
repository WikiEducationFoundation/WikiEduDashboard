# frozen_string_literal: true

require 'rails_helper'
require "#{Rails.root}/lib/experiments/opt_in_experiment"

# Covers the instructor-facing opt-in panel for an active research experiment,
# which the researchwrite wizard shows via `only_if:
# 'eligible_for_active_research_experiment'`.
#
# COUPLING: `only_if` is evaluated client-side as `course[panel.only_if]` (see
# filterPanels in app/assets/javascripts/reducers/wizard.js), so the panel is
# silently dropped for every course if that predicate stops being serialized in
# app/views/courses/course.json.jbuilder. That is exactly the regression these
# examples exist to catch — it is invisible to the rest of the suite, since the
# wizard specs in course_creation_spec.rb use 2015 course dates and so never
# reach this panel.
describe 'research experiment wizard opt-in', type: :feature, js: true do
  let(:instructor) do
    create(:user, username: 'Alice Nakamura', permissions: User::Permissions::INSTRUCTOR)
  end
  let(:panel_title) { 'Please participate in our research experiment' }

  before do
    allow(Features).to receive(:wiki_ed?).and_return(true)
    allow(Features).to receive(:disable_wiki_output?).and_return(true)
    # The panel is offered whether or not the student-facing side is live.
    allow(Features).to receive(:fall_2026_research_student_optin?).and_return(false)
    TrainingModule.load_all
  end

  after { logout }

  def course_starting(start_date, slug_term)
    create(:course, title: 'Environmental Policy',
                    school: 'Northwestern University',
                    slug: "Northwestern_University/Environmental_Policy_(#{slug_term})",
                    submitted: false,
                    passcode: 'passcode',
                    start: start_date,
                    end: start_date + 100.days,
                    timeline_start: start_date,
                    timeline_end: start_date + 100.days)
  end

  # Walks the wizard as far as the panel after assignment selection, which is
  # where the research opt-in panel appears for an eligible course. Mirrors
  # go_through_course_dates_and_timeline_dates in course_creation_spec.rb.
  def advance_to_panel_after_assignment_selection(course)
    create(:courses_user, user: instructor, course:,
                          role: CoursesUsers::Roles::INSTRUCTOR_ROLE)
    login_as(instructor, scope: :user)
    visit "/courses/#{course.slug}/timeline/wizard"
    expect(page).to have_css('.wizard__panel.active')
    find('span[title="Wednesday"]', match: :first).click
    within('.wizard__panel.active') do
      expect(page).not_to have_css('button.dark[disabled]')
    end
    click_button 'Next'
    # Wait out the panel transition before clicking, or the option click can be
    # dropped and the wizard stays on the assignment panel (as in
    # go_through_course_dates_and_timeline_dates in course_creation_spec.rb).
    sleep 1
    find('.wizard__option', match: :first).find('button', match: :first).click
    expect(page).to have_css('.wizard__option.selected')
    click_button 'Next'
    expect(page).to have_css('.wizard__panel.active')
  end

  it 'offers the opt-in panel to a course eligible for an active experiment' do
    course = course_starting(Date.new(2026, 9, 1), 'Fall_2026')
    expect(course.eligible_for_active_research_experiment?).to be true

    advance_to_panel_after_assignment_selection(course)

    expect(page).to have_content(panel_title)
    expect(page).to have_content('Yes, my class will participate')
  end

  it 'skips the opt-in panel for a course that is not eligible' do
    course = course_starting(Date.new(2026, 1, 15), 'Spring_2026')
    expect(course.eligible_for_active_research_experiment?).to be false

    advance_to_panel_after_assignment_selection(course)

    # The wizard moves straight on to the panel that follows it.
    expect(page).to have_content('Training')
    expect(page).to have_no_content(panel_title)
  end
end
