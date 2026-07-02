# frozen_string_literal: true

require 'fileutils'

# Saves a PNG of the current Capybara session's page into a named
# directory. Used by the screenshot specs that document the Canvas
# integration's UX surface by surface, per role.
#
# Distinct from `failure_screenshot.rb` (which fires only when an example
# raises): these are deliberate captures at named moments of a *passing*
# walkthrough. Because it screenshots whatever session is current, calling
# it inside `in_student_browser` captures the student's Chrome profile.
module ScreenshotHelper
  def save_screenshot_to(dir, name)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "#{name}.png")
    page.save_screenshot(path)
    warn "  [screenshot] #{path}"
    path
  end

  # Per-role output directory for the deliberate UX captures. Overridable via
  # CANVAS_SHOTS_DIR so `bin/harvest-canvas-screenshots` can point every role
  # spec at one run directory. Defaults under tmp/ (gitignored) — these
  # screenshots are surfaced via the harvest gallery, never committed.
  def canvas_shots_dir(subdir)
    base = ENV.fetch('CANVAS_SHOTS_DIR') do
      File.expand_path('../../../tmp/canvas-ux-screenshots', __dir__)
    end
    dir = File.join(base, subdir)
    FileUtils.mkdir_p(dir)
    dir
  end

  # Scroll an element to the middle of the viewport before capturing, so
  # sidebar surfaces (like the LMS-integration status panel) aren't below
  # the fold in the screenshot. Returns the element.
  def scroll_into_view(selector)
    el = find(selector)
    page.execute_script('arguments[0].scrollIntoView({ block: "center" })', el)
    el
  end

  # Screenshot the whole page, not just the viewport, so a surface that lives
  # below the fold — like the LMS-integration status panel in the course sidebar
  # — is included. Grows the window to the document height and uses the reliable
  # viewport-capture path (direct CDP element/full-page capture hangs against
  # this harness's software renderer). Needs a headless run: a nested Xephyr
  # screen can't grow past its fixed height. Dismiss the consent banner first, or
  # its fixed bottom overlay covers whatever sits at the fold.
  def save_full_page_screenshot_to(dir, name)
    window = page.current_window
    original = window.size
    height = [page.evaluate_script('document.documentElement.scrollHeight').to_i + 120, 4000].min
    window.resize_to(original.first, height)
    sleep 0.4 # let the taller layout settle before capturing
    save_screenshot_to(dir, name)
  ensure
    window.resize_to(*original)
  end
end
