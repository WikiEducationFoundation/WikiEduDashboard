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

  # Scroll an element to the middle of the viewport before capturing, so
  # sidebar surfaces (like the LMS-integration status panel) aren't below
  # the fold in the screenshot. Returns the element.
  def scroll_into_view(selector)
    el = find(selector)
    page.execute_script('arguments[0].scrollIntoView({ block: "center" })', el)
    el
  end
end
