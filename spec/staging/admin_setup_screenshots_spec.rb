# frozen_string_literal: true

require_relative 'spec_helper'

# Read-only capture of the Canvas admin's view of the installed Wiki Education
# LTI tool on canvas.wikiedu.org: the developer key, the app in Canvas Apps,
# its availability, and the placements it adds.
#
# Runs as a **root-account-only admin** (CANVAS_TEST_ADMIN_*), not the Site
# Admin user behind CANVAS_ADMIN_TOKEN. That distinction is the point: a Site
# Admin's Admin menu lists Site Admin rather than the institution's account,
# and registering from there installs the tool where no course can reach it —
# a wrong turn a Canvas-hosted institution's admin cannot take, so the
# screenshots would misrepresent their experience.
#
# Read-only by design. The create -> configure -> teardown walk is deliberately
# *not* automated: LTIAAS refuses to register a platform that is already
# registered, so an automated run would have to delete the live registration
# first, taking the developer key, its AGS line items, and the working demo
# course down with it on every run. Registration-dialog screenshots are
# captured by hand during a real re-registration instead.
#
#   bin/staging-feature-spec spec/staging/admin_setup_screenshots_spec.rb
#
# Output goes to the harvest run dir (`tmp/canvas-ux-screenshots/admin/`,
# override with CANVAS_SHOTS_DIR); `bin/harvest-canvas-screenshots` collects it.
describe 'Canvas admin setup (read-only) screenshots', :staging do
  let(:required_env) do
    %w[CANVAS_TEST_ADMIN_LOGIN CANVAS_TEST_ADMIN_PASSWORD CANVAS_TEST_ACCOUNT_ID]
  end

  # The tool takes its name from the LTIAAS tenant; the testing tenant is
  # "wikiedu.org testing" where production is "wikiedu.org".
  let(:tool_name)      { ENV.fetch('CANVAS_TOOL_LABEL', 'wikiedu.org testing') }
  let(:account_id)     { ENV.fetch('CANVAS_TEST_ACCOUNT_ID', '1') }
  let(:screenshot_dir) { canvas_shots_dir('admin') }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?
  end

  it 'captures the developer key, the installed app, and its availability' do
    in_admin_browser do
      in_canvas do
        ensure_canvas_logged_in_as_admin

        visit "/accounts/#{account_id}/developer_keys"
        expect(page).to have_content(tool_name, wait: 20)
        capture('a01-developer-keys')

        visit "/accounts/#{account_id}/apps"
        find('[role="tab"]', text: 'Manage', wait: 15).click
        expect(page).to have_content(tool_name, wait: 20)
        capture('a02-canvas-apps-manage')

        open_installed_app
        capture('a03-app-overview')
        show_availability
        capture('a04-app-availability')
        # The Configuration tab opens on Permissions, with the two settings the
        # guide describes — data sharing and the placement set — below the
        # fold. The panel scrolls in its own container, so scrollIntoView
        # doesn't move it; grow the window and take the whole tab in one shot.
        find('[role="tab"], button, a', text: 'Configuration', match: :first, wait: 15).click
        expect(page).to have_text(/Permissions|Data Sharing/i, wait: 20)
        scroll_panel_to('Data Sharing')
        capture('a05-app-data-sharing')
        scroll_panel_to('Placements')
        capture('a06-app-placements')
      end
    end
  end

  private

  # Open the app's own page from the Apps > Manage list.
  def open_installed_app
    find('a, button', text: tool_name, match: :first, wait: 20).click
    # The app page leads with its name and carries the configuration sections
    # (data sharing, placements, availability) beneath.
    expect(page).to have_text(/Availability|Placements|Data Sharing|data shared/i, wait: 30)
    sleep 2 # let the panel finish rendering before capturing
  end

  # Bring the availability/exceptions section into view — that's the control
  # that decides whether any course can see the tool at all, and the one an
  # install is most likely to have left untouched.
  def show_availability
    scroll_to_text(/Availability|Exception/i)
  rescue Capybara::ElementNotFound
    scroll_to_text(/Placements/i)
  end

  def scroll_to_text(pattern)
    el = find(:xpath, "//*[text()]", text: pattern, match: :first, wait: 15)
    page.execute_script('arguments[0].scrollIntoView({ block: "start" })', el)
    sleep 1
  end

  # Bring a section of the app panel into view by scrolling the panel's own
  # scroll container. The Apps page renders the configuration inside a
  # scrollable div with a sticky footer, so neither `scrollIntoView` nor
  # growing the window moves it — the document itself never scrolls. Walks up
  # from the matched heading to the first genuinely scrollable ancestor.
  def scroll_panel_to(heading)
    result = page.evaluate_script(<<~JS)
      (function () {
        var nodes = Array.prototype.slice.call(document.querySelectorAll('h1,h2,h3,h4,legend,span,div'));
        var el = nodes.filter(function (n) {
          return n.children.length === 0 && /#{heading}/i.test(n.textContent || '');
        })[0];
        if (!el) { return 'heading not found'; }
        var p = el.parentElement;
        while (p && p !== document.body) {
          var style = window.getComputedStyle(p);
          var scrolls = (style.overflowY === 'auto' || style.overflowY === 'scroll');
          if (scrolls && p.scrollHeight > p.clientHeight + 20) {
            p.scrollTop += el.getBoundingClientRect().top - p.getBoundingClientRect().top - 16;
            return 'scrolled container';
          }
          p = p.parentElement;
        }
        el.scrollIntoView({ block: 'start' });
        return 'scrolled document';
      })()
    JS
    warn "  [scroll] #{heading}: #{result}"
    sleep 1
  end

  def capture(name)
    save_screenshot_to(screenshot_dir, name)
  end
end
