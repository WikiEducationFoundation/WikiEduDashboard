# frozen_string_literal: true

# Helpers that drive the Canvas → dashboard LTI launch flow inside a
# persistent-profile Chrome browser. Assumes the profile is already
# bootstrapped (one-time manual login to Canvas + one-time approval
# of the Wiki Education Dashboard's Wikipedia OAuth grant). See
# `docs/staging_feature_specs.md` for the bootstrap procedure.
#
# Selectors are best-guess for Canvas's stock UI; first real run may
# need them tweaked. TODO markers below flag the suspects.
module LaunchHelpers
  # Visit a Canvas course in the active session (the surrounding spec
  # is expected to have called `in_canvas`).
  def visit_canvas_course(canvas_course_id)
    visit "/courses/#{canvas_course_id}"
    expect(page).to have_no_text('Please log in', wait: 2)
  end

  # Click the Wiki Education Dashboard tab in the Canvas course nav.
  # TODO: confirm the link text; Canvas uses `:text` for nav items but
  # the placement text comes from our developer-key config
  # ("Wiki Education Dashboard").
  def click_wiki_education_tab
    within('nav#section-tabs, #section-tabs') do
      click_link 'Wiki Education Dashboard'
    end
  end

  # The Canvas tool placement renders our `/lti` view inside an iframe
  # whose id is `tool_content` (Canvas's stock external-tool iframe).
  # Click the "Open the Wiki Education Dashboard" button inside it,
  # then switch focus to the new tab that target=_blank opens, and
  # walk the Wikipedia OAuth bounce if it appears (handled silently
  # when the OAuth grant is already in place on Wikipedia's side).
  def break_out_of_canvas_iframe(role: :instructor, iframe: canvas_tool_iframe_locator)
    open_dashboard_from_iframe(iframe)
    switch_to_new_tab
    # The connect_course tab occasionally comes back a bare staging 500;
    # reload it before walking the OAuth bounce.
    wait_out_server_error
    complete_wikipedia_oauth_if_needed(role: role)
  end

  # The in-iframe /lti launch intermittently returns a bare 500 (a staging
  # infra hiccup that never reaches Rails), leaving the iframe without the
  # "Open the Wiki Education Dashboard" link. Reload the Canvas page to
  # re-launch the tool and retry before giving up.
  def open_dashboard_from_iframe(iframe, attempts: 4)
    attempts.times do |i|
      frame = first(iframe, wait: 10)
      return if frame && within_frame(frame) { click_dashboard_link_if_present }

      warn "  [retry] Canvas tool iframe had no dashboard link " \
           "(attempt #{i + 1}/#{attempts}); reloading Canvas page"
      page.refresh
    end
    raise 'Canvas tool iframe never rendered the dashboard link after reloads ' \
          '(likely an intermittent staging 500 inside the iframe)'
  end

  def click_dashboard_link_if_present
    return false unless has_link?('Open the Wiki Education Dashboard', wait: 5)

    click_link 'Open the Wiki Education Dashboard'
    true
  end

  # Reload the current page while it's showing a bare staging 500, up to
  # `attempts` times. No-op when the page isn't an error; raises if it never
  # clears (so a genuinely down server still fails loudly).
  def wait_out_server_error(attempts: 4)
    attempts.times do |i|
      return unless on_server_error?

      warn "  [retry] staging returned a 500; reloading (attempt #{i + 1}/#{attempts})"
      page.refresh
      sleep 1
    end
    raise 'staging kept returning a 500 after reloads' if on_server_error?
  end

  # Signature of the intermittent bare Apache/Passenger 500 — it never reaches
  # Rails, so it's the generic server-error page, not a dashboard error view.
  # Guarded because the caller may check mid-navigation (e.g. the OAuth-redirect
  # tab), when the document root isn't queryable yet; "can't tell" means "not an
  # error" so the caller's own waits take over.
  def on_server_error?
    page.has_content?('Internal Server Error', wait: 0)
  rescue Capybara::ElementNotFound, Selenium::WebDriver::Error::WebDriverError
    false
  end

  # The LMS-status panel renders from a `lms_integration_status.json` fetch,
  # which is subject to the same intermittent staging edge-500. That fetch
  # degrades gracefully client-side (the panel just doesn't render), so a
  # transient 500 silently costs us the screenshot. Reload a few times so one
  # bad fetch doesn't fail the walk; assert on the last try.
  def await_lms_panel(attempts: 3)
    attempts.times do
      return if page.has_css?('.lms-integration-status', wait: 20)

      page.refresh
    end
    expect(page).to have_css('.lms-integration-status', wait: 20)
  end

  # Canvas's external-tool iframe has a dynamic id `tool_content_<N>`
  # (the N is the assignment / placement id, which changes per launch
  # context). Stable selectors: `iframe.tool_launch` and
  # `iframe[data-lti-launch="true"]`.
  def canvas_tool_iframe_locator
    'iframe.tool_launch'
  end

  # On a Canvas assignment page (the assignment_view placement), the tool
  # iframe can carry a different id/class than the course-nav tab's, so
  # accept any of the stock external-tool iframe selectors. The
  # assignment_view entry-point diagnostic confirmed one of these is
  # present on an AGS-created column's assignment page.
  def canvas_assignment_iframe_locator
    'iframe.tool_launch, iframe[data-lti-launch="true"], iframe#tool_content'
  end

  # Dismiss the dashboard's react-cookie-consent banner if it's visible.
  # The "I understand" click sets a long-lived cookie, so the banner
  # only obstructs the bottom of the viewport on the first page load
  # of a fresh session. Safe no-op when the banner is absent.
  def dismiss_consent_banner
    return unless page.has_css?('.consent-banner', wait: 2)

    within('.consent-banner') { click_button 'I understand' }
  rescue Capybara::ElementNotFound
    # Banner vanished between detection and click — fine.
  end

  # The full instructor first-launch sequence, end to end: Canvas login →
  # course → Wiki Education tab → break out of the iframe → Wikipedia
  # OAuth (silent once bootstrapped) → dashboard setup view → link the
  # course → land on /courses/<slug>. Runs in whatever Capybara session
  # is current, which is the default (instructor) profile for
  # single-persona specs. Specs that also need the student persona run
  # this in the default session and the student walk inside
  # `in_student_browser`. The binding is what captures the LTIAAS
  # service_key, so this step is a prerequisite for any roster/grade sync.
  def bind_course_as_instructor(canvas_course_id:, course_slug:, granularity: 'lumped')
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_canvas_course(canvas_course_id)
      click_wiki_education_tab
      break_out_of_canvas_iframe(role: :instructor)
    end
    dismiss_consent_banner
    complete_dashboard_setup(course_slug:, granularity:)
    expect(page).to have_current_path(%r{/courses/}, wait: 20)
  end

  # The instructor launch up to — but not through — the setup view: the
  # binding is created (with a nil course) but never linked to a Dashboard
  # course. Leaves the LMS course in the "instructor hasn't finished setup"
  # state a student then hits as `setup_pending`. Runs in the current
  # (instructor) session.
  def reach_instructor_setup_view(canvas_course_id:)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit_canvas_course(canvas_course_id)
      click_wiki_education_tab
      break_out_of_canvas_iframe(role: :instructor)
    end
    dismiss_consent_banner
    expect(page).to have_content('Set up the Wiki Education Dashboard')
  end

  # On the dashboard's setup view, identify the course we want to link
  # and submit. The form's `course_slug` field is a select whose
  # options' visible text is the slug itself; older deployed-staging
  # builds rendered it as a text input, so the helper branches.
  def complete_dashboard_setup(course_slug:, granularity: 'lumped')
    submit_course_link(course_slug:, granularity:)
    # The setup POST occasionally 500s on staging; go back to the form and
    # resubmit rather than failing the whole walk on a transient blip.
    2.times do
      break if page.has_current_path?(%r{/courses/}, url: true, wait: 20)
      break unless on_server_error?

      warn '  [retry] setup POST returned a 500; going back and resubmitting'
      page.go_back
      submit_course_link(course_slug:, granularity:)
    end
    expect(page).to have_current_path(%r{/courses/}, url: true, wait: 30)
  end

  # Pick the course + granularity on the setup view and submit. The
  # `course_slug` field is a select whose option text is the slug; older
  # deployed builds rendered a text input, so branch on what's present.
  def submit_course_link(course_slug:, granularity: 'lumped')
    expect(page).to have_content('Set up the Wiki Education Dashboard')
    if page.has_select?('course_slug')
      select course_slug, from: 'course_slug'
    else
      fill_in 'course_slug', with: course_slug
    end
    # `lumped` is the default-checked radio; only click for a different value.
    find(:css, "input[type=radio][value='#{granularity}']").click if granularity != 'lumped'
    click_button 'Link this course'
  end

  # Walk the dashboard's React onboarding flow as a real first-time
  # student would: Intro → Form (real_name + email; the role question is
  # hidden via `isLtiLaunchUrl(returnToParam)` because we're returning to
  # `/lti?ltik=...`) → Permissions → Finished (auto-redirects via
  # `window.location` to the `return_to` URL). A silent no-op when the
  # student is already onboarded — `check_onboarded` doesn't redirect, so
  # `current_url` doesn't include `/onboarding` and the helper returns
  # immediately. Letting both states run through the same call keeps the
  # spec realistic for either a brand-new dashboard user or a returning
  # one, without faking the onboarded flag.
  def walk_through_onboarding(real_name:, email:)
    return unless page.current_url.include?('/onboarding')

    click_link 'Start'
    expect(page).to have_field('onboarding-name', wait: 15)
    fill_in 'onboarding-name', with: real_name
    fill_in 'onboarding-email', with: email
    click_button 'Submit'
    expect(page).to have_link('Finish', wait: 15)
    click_link 'Finish'
    # finished.jsx's useEffect window.location's to the return_to URL after
    # ~750 ms; subsequent assertions catch the resulting landing.
  end
end
