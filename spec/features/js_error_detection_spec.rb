# frozen_string_literal: true

require 'rails_helper'

# Meta-test: verifies that SEVERE JavaScript console errors are captured in
# browser logs and detectable after page navigation — the same mechanism the
# after(:each) hook in rails_helper uses to fail specs on JS errors.
#
# Uses js_error_expected: true so the after hook skips its own check; instead
# we call check_for_severe_js_errors directly (the same method the hook uses)
# so this test stays in sync with the real detection logic.
describe 'JS error detection', type: :feature, js: true, js_error_expected: true do
  let(:course) { create(:course) }
  let(:admin) { create(:admin) }

  before do
    stub_token_request
    login_as(admin, scope: :user)
  end

  it 'detects SEVERE errors in browser logs after page navigation' do
    visit "/courses/#{course.slug}"
    expect(page).to have_content course.title

    page.execute_script(<<~JS)
      var s = document.createElement('script');
      s.textContent = 'throw new Error("Intentional test error for JS error detection")';
      document.head.appendChild(s);
    JS

    click_link 'Home'
    expect(page).to have_content 'My Dashboard'

    # Call the same method the after(:each) hook uses. If this stops catching
    # the injected error, it means the detection mechanism is broken.
    errors = page.driver.browser.logs.get(:browser)
    expect { check_for_severe_js_errors(errors) }
      .to raise_error(RSpec::Expectations::ExpectationNotMetError)
  end
end
