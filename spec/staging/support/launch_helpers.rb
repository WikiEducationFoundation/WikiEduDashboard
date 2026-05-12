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
  def break_out_of_canvas_iframe(role: :instructor)
    frame = find(canvas_tool_iframe_locator)
    within_frame(frame) do
      click_link 'Open the Wiki Education Dashboard'
    end
    switch_to_new_tab
    complete_wikipedia_oauth_if_needed(role: role)
  end

  # Canvas's external-tool iframe has a dynamic id `tool_content_<N>`
  # (the N is the assignment / placement id, which changes per launch
  # context). Stable selectors: `iframe.tool_launch` and
  # `iframe[data-lti-launch="true"]`.
  def canvas_tool_iframe_locator
    'iframe.tool_launch'
  end

  # On the dashboard's setup view, identify the course we want to link
  # and submit. Handles both the new dropdown UX (commit `f41ed09b2`)
  # and the older text-input form that earlier-deployed staging may
  # still be running — either way the form's `course_slug` field's
  # value is the slug. Pass both `course_slug:` and `course_title:`
  # so the helper can branch.
  def complete_dashboard_setup(course_slug:, course_title:, granularity: 'lumped')
    expect(page).to have_content('Set up the Wiki Education Dashboard')
    if page.has_select?('course_slug')
      select course_title, from: 'course_slug'
    else
      fill_in 'course_slug', with: course_slug
    end
    # `lumped` is the default-checked radio in the view; only click
    # when a different granularity is requested.
    find(:css, "input[type=radio][value='#{granularity}']").click if granularity != 'lumped'
    click_button 'Link this course'
  end
end
