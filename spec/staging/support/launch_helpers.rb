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

  # Reload the Canvas page until the tool iframe renders the launch landing
  # (the "Open the Wiki Education Dashboard" link) — riding through the
  # intermittent edge-500 that can hit the in-iframe /lti launch. Returns the
  # settled iframe element, so a caller can screenshot a *clean* landing before
  # breaking out (rather than freezing a transient 500 into the gallery).
  def settle_canvas_tool_iframe(iframe = canvas_tool_iframe_locator, attempts: 4)
    attempts.times do |i|
      frame = first(iframe, wait: 10)
      return frame if frame && iframe_shows_landing?(frame)

      warn "  [retry] Canvas tool iframe not showing the launch landing " \
           "(attempt #{i + 1}/#{attempts}); reloading Canvas page"
      page.refresh
    end
    raise 'Canvas tool iframe never rendered the launch landing after ' \
          'reloads (likely an intermittent staging 500 inside the iframe)'
  end

  def open_dashboard_from_iframe(iframe)
    frame = settle_canvas_tool_iframe(iframe)
    within_frame(frame) { click_link 'Open the Wiki Education Dashboard' }
  end

  def iframe_shows_landing?(frame)
    within_frame(frame) { has_link?('Open the Wiki Education Dashboard', wait: 5) }
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

  # The student-side Canvas walk: log into Canvas, open the course's Wiki
  # Education tab, break out of the iframe through Wikipedia OAuth, and land
  # at top level on the dashboard. `before_breakout` runs after the tab is
  # open but before the break-out, for capturing the in-iframe landing. A
  # brand-new dashboard user gets routed through /onboarding before the LTI
  # launch resumes; walk it (silent no-op on a returning, already-onboarded
  # user). Must be called inside `in_student_browser`.
  def student_walk_to_dashboard(canvas_course_id:, email:, before_breakout: nil)
    in_canvas do
      ensure_canvas_logged_in_as_student
      visit_canvas_course(canvas_course_id)
      click_wiki_education_tab
      before_breakout&.call
      break_out_of_canvas_iframe(role: :student)
    end
    dismiss_consent_banner
    walk_through_onboarding(real_name: 'LTI Test Student', email:)
  end

  # Create a Canvas assignment via LTI deep linking, bound to a Dashboard
  # gradable (an exercise block or the trainings rollup), so launching it opens
  # the assignment_view. Drives Canvas's new-assignment editor → External Tool →
  # "Find" dialog → our picker → Select → publish, in the instructor session.
  # `gradable_label` picks the gradable in the deep-link picker (its radio label);
  # `assignment_name` is the Canvas assignment's own name. Keep them distinct when
  # the gradable already has an auto-synced gradebook column of the same name, so
  # the created assignment is unambiguously findable.
  def create_deep_linked_assignment(course_id:, gradable_label:, assignment_name: gradable_label)
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      visit "/courses/#{course_id}/assignments/new"
      select 'External Tool', from: 'Submission Type'
      click_button 'Find'
      pick_gradable_in_deep_link_dialog(gradable_label)
      fill_in 'assignment_name', with: assignment_name
      fill_in 'assignment_points_possible', with: '1'
      find('.save_and_publish').click
    end
    dismiss_consent_banner
  end

  # Inside Canvas's External Tool "Find" dialog: click our tool, pick the gradable
  # in the deep-link picker (served in the resource-selection iframe) and submit.
  # Canvas stages the returned content item into the dialog's hidden line-item
  # field; wait for that, then Select to apply + close the dialog.
  def pick_gradable_in_deep_link_dialog(gradable_label)
    within('#context_external_tools_select') { click_link 'wikiedu.org testing key' }
    within_frame(find('#resource_selection_iframe', wait: 20)) do
      choose(gradable_label, wait: 20)
      find('button[type="submit"]').click
    end
    staged = eventually(attempts: 30, interval: 1) do
      find('#external_tool_create_line_item', visible: false).value.to_s.include?(gradable_label)
    end
    expect(staged).to be_truthy
    find('.add_item_button', text: 'Select').click
    expect(page).to have_no_css('.add_item_button', wait: 15)
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
  # `course_slug` select is labelled with the readable course title but its
  # option value is the slug, so pick by value; older deployed builds
  # rendered a text input, so branch on what's present.
  def submit_course_link(course_slug:, granularity: 'lumped')
    expect(page).to have_content('Set up the Wiki Education Dashboard')
    if page.has_select?('course_slug')
      find("#course_slug option[value='#{course_slug}']").select_option
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
