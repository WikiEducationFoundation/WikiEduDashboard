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
# spec) are NOT supported by this helper. Two Capybara `using_session`
# instances would each try to spin up their own Chrome process pointed
# at the same persistent `user-data-dir`, which Chrome refuses. T3
# specs that need that pattern will register dedicated drivers with
# distinct profile dirs (one per persona).
module StagingSessions
  CANVAS_HOST    = 'https://canvas.wikiedu.org'
  DASHBOARD_HOST = 'https://dashboard-testing.wikiedu.org'

  def in_canvas(&block)
    with_app_host(CANVAS_HOST, &block)
  end

  def in_dashboard(&block)
    with_app_host(DASHBOARD_HOST, &block)
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
