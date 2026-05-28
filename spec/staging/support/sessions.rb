# frozen_string_literal: true

# Cross-origin helpers. The Canvas integration spans two hosts
# (`canvas.wikiedu.org` for the LMS side, `dashboard-testing.wikiedu.org`
# for the dashboard side), and Capybara's `app_host` is single-valued.
# These helpers temporarily swap the host so a single browser session
# can drive both — which matches how the real launch flow works
# (one Chrome instance, iframe-to-new-tab handoff, same cookie jar
# across both origins).
#
# Multi-persona scenarios (e.g., instructor and student in the same
# spec) ARE supported via `in_student_browser`: it runs its block in a
# dedicated Capybara session backed by the `:staging_chrome_student`
# driver, whose profile dir is distinct from the default instructor
# profile, so the two Chrome processes don't fight over one
# `--user-data-dir`. The default (instructor) session is restored when
# the block returns. Specs that don't need the student persona never
# touch the student driver and pay nothing.
module StagingSessions
  CANVAS_HOST    = 'https://canvas.wikiedu.org'
  DASHBOARD_HOST = 'https://dashboard-testing.wikiedu.org'

  def in_canvas(&block)
    with_app_host(CANVAS_HOST, &block)
  end

  def in_dashboard(&block)
    with_app_host(DASHBOARD_HOST, &block)
  end

  # Run a block as the student persona: a separate Capybara session on
  # the `:staging_chrome_student` driver (its own profile dir, its own
  # Canvas + Wikipedia-OAuth state). `app_host` is global, so nest the
  # `in_canvas` / `in_dashboard` helpers inside this block as usual.
  # Restores the prior driver + session on exit.
  def in_student_browser(&block)
    Capybara.using_driver(:staging_chrome_student) do
      Capybara.using_session(:student, &block)
    end
  end

  # Follow a `target=_blank` link to the new tab the click opened.
  # Selenium reports the new tab as another window handle; switch
  # the active window so subsequent `page.visit` / `find` / etc. talk
  # to it.
  def switch_to_new_tab
    handles = page.driver.browser.window_handles
    page.driver.browser.switch_to.window(handles.last)
  end

  private

  def with_app_host(host)
    previous = Capybara.app_host
    Capybara.app_host = host
    yield
  ensure
    Capybara.app_host = previous
  end
end
