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
  # Restores the prior driver + session on exit. On failure, snapshots
  # the student session before unwinding — the after-hook's
  # `Capybara.current_session` reverts to the default (instructor) once
  # `using_session` returns, so without this, every student-side failure
  # would silently capture the wrong browser.
  def in_student_browser(&block)
    Capybara.using_driver(:staging_chrome_student) do
      Capybara.using_session(:student, &block)
    end
  ensure
    # Use ensure + $! (instead of `rescue StandardError`) so we catch
    # RSpec::Expectations::ExpectationNotMetError too — it inherits from
    # Exception, not StandardError, and would slip past a rescue here.
    capture_student_failure_artifact if $!
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

  def capture_student_failure_artifact
    Capybara.using_driver(:staging_chrome_student) do
      Capybara.using_session(:student) do
        require 'fileutils'
        dir = File.join(FAILURE_ARTIFACT_DIR, "student_session_#{Time.now.to_i}")
        FileUtils.mkdir_p(dir)
        Capybara.current_session.save_screenshot(File.join(dir, 'screenshot.png'))
        File.write(File.join(dir, 'page.html'), Capybara.current_session.html)
        dump_browser_console(Capybara.current_session, dir)
        warn "  [student-failure-artifact] saved to #{dir} " \
             "(at #{Capybara.current_session.current_url})"
      end
    end
  rescue StandardError => e
    warn "  [student-failure-artifact] couldn't capture: #{e.message}"
  end

  # Write the browser console log (uncaught JS errors, console.error) next to
  # the failure artifact when the driver captured any — the thing that
  # explains a blank React render. Needs goog:loggingPrefs on the driver
  # (set in spec_helper). No-op / quiet when the log type isn't available.
  def dump_browser_console(session, dir)
    entries = session.driver.browser.logs.get(:browser)
    return if entries.nil? || entries.empty?

    File.write(File.join(dir, 'console.log'),
               entries.map { |e| "[#{e.level}] #{e.message}" }.join("\n"))
  rescue StandardError => e
    warn "  [console] couldn't capture browser log: #{e.message}"
  end
end
