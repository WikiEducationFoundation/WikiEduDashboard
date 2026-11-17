# frozen_string_literal: true

require 'rails_helper'

describe 'List.js #users initialization', type: :feature, js: true do
  let(:course) { create(:course, start: 3.months.ago, end: 3.months.from_now) }
  let(:student) { create(:user, username: 'StudentUser') }

  before do
    create(:courses_user, course:, user: student, role: CoursesUsers::Roles::STUDENT_ROLE)
  end

  # course.js runs `new List('users', ...)` from document.onreadystatechange,
  # racing React's render of the Students tab. Re-dispatching the event after
  # the React table is on the page makes the race deterministic.
  it 'logs no JS errors when the course.js handler runs after React renders #users',
     js_error_expected: true do
    visit "/courses/#{course.slug}/students/overview"
    expect(page).to have_css('table.users', text: 'StudentUser')
    sleep 1
    page.driver.browser.logs.get(:browser) # drain earlier entries

    page.execute_script("document.dispatchEvent(new Event('readystatechange'))")
    sleep 0.5
    severe = page.driver.browser.logs.get(:browser).select { |e| e.level == 'SEVERE' }
    expect(severe.map(&:message)).to be_empty
  end
end
