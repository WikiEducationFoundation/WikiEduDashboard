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
  # then switch focus to the new tab that target=_blank opens.
  def break_out_of_canvas_iframe
    within_frame(canvas_tool_iframe_locator) do
      click_link 'Open the Wiki Education Dashboard'
    end
    switch_to_new_tab
  end

  # TODO: Canvas's external-tool iframe is usually `<iframe id="tool_content">`,
  # but on some pages it's nested inside `<div id="tool_content_wrapper">`.
  # First real run will tell us which one is right.
  def canvas_tool_iframe_locator
    'tool_content'
  end

  # On the dashboard's setup view, pick the course from the dropdown and
  # submit. Returns the slug we picked so the caller can assert the
  # redirect.
  def complete_dashboard_setup(course_title:, granularity: 'lumped')
    expect(page).to have_content('Set up the Wiki Education Dashboard')
    select course_title, from: 'course_slug'
    choose granularity if page.has_field?('gradebook_granularity', with: granularity, type: 'radio')
    click_button 'Link this course'
  end
end
