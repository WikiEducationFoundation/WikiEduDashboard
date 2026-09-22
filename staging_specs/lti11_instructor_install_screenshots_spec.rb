# frozen_string_literal: true

require_relative 'spec_helper'

# Illustrations for the instructor-facing LTI 1.1 install page
# (docs/canvas_instructor_install.md, served at /lti/guide/instructors): the
# real Canvas dialog a teacher uses to add the Dashboard to one course,
# captured step by step as the test instructor on canvas.wikiedu.org, with the
# tool installed nowhere else so the "before" state is honest.
#
# Writes PNGs to tmp/canvas-ux-screenshots/instructor_install/ (override with
# CANVAS_SHOTS_DIR). The dialog is photographed with placeholder text in the
# credential fields, then filled with the real key/secret (never captured) to
# actually install and show the resulting tab. Provisions and tears down its
# own Canvas course, its own Dashboard course, and its own consumer key, and
# tears all three down afterwards.
describe 'LTI 1.1 instructor install screenshots', :staging do
  let(:canvas_course_name) { 'Introduction to Environmental Policy' }

  # The name this walkthrough types into the Add App dialog, which is also what
  # Canvas puts in the course nav. Overrides LaunchHelpers#tool_label, whose
  # default names the account-wide 1.3 tool rather than this course's install.
  def tool_label
    'wikiedu.org'
  end

  let(:required_env) do
    %w[CANVAS_ADMIN_TOKEN CANVAS_TEST_ACCOUNT_ID CANVAS_TEST_INSTRUCTOR_USER_ID
       CANVAS_TEST_INSTRUCTOR_LOGIN CANVAS_TEST_INSTRUCTOR_PASSWORD
       WIKIPEDIA_TEST_INSTRUCTOR_USERNAME DASHBOARD_TEST_CAMPAIGN_SLUG]
  end
  let(:run_id)     { Time.now.strftime('%Y%m%d%H%M%S') }
  let(:canvas_api) { CanvasApiClient.new }
  let(:shots)      { canvas_shots_dir('instructor_install') }
  let(:provisioned) { @provisioned ||= {} }
  let(:dashboard_base) { ENV.fetch('DASHBOARD_BASE_URL', 'https://dashboard-testing.wikiedu.org') }
  let(:launch_url) { "#{dashboard_base}/lti/legacy/launch" }
  let(:config_url_shown) { 'https://dashboard.wikiedu.org/lti/legacy/config.xml' }
  let(:config_url_real) { 'https://dashboard-testing.wikiedu.org/lti/legacy/config.xml' }

  before do
    missing = required_env.select { |k| ENV[k].to_s.empty? }
    skip("missing env vars: #{missing.join(', ')}") if missing.any?

    course = canvas_api.create_course(name: canvas_course_name,
                                      course_code: "ENVS-350-#{run_id}")
    provisioned[:canvas_course_id] = course['id']
    canvas_api.enroll_user(course_id: course['id'],
                           user_id: ENV.fetch('CANVAS_TEST_INSTRUCTOR_USER_ID'),
                           role: 'TeacherEnrollment')

    # Credentials are per course and issued by the Dashboard now, so the
    # walkthrough provisions a Dashboard course and issues a key for it, the
    # way an instructor would from their own credentials page.
    dashboard_course = DashboardAdminClient.create_course(
      title: "Screenshot Install #{run_id}", school: 'StagingTest', term: run_id,
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
    provisioned[:dashboard_course_slug] = dashboard_course['slug']
    DashboardAdminClient.approve_course(slug: dashboard_course['slug'],
                                        campaign_slug: ENV.fetch('DASHBOARD_TEST_CAMPAIGN_SLUG'))
    @credentials = DashboardAdminClient.issue_lti_consumer_key(
      course_slug: dashboard_course['slug'],
      instructor_username: ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME')
    )
  end

  after do
    if provisioned[:canvas_course_id]
      canvas_api.delete_course(course_id: provisioned[:canvas_course_id])
    end
    return unless provisioned[:dashboard_course_slug]

    DashboardAdminClient.delete_bindings_for(context_title: canvas_course_name)
    DashboardAdminClient.delete_course(slug: provisioned[:dashboard_course_slug])
  end

  def shoot(name, selector: nil)
    sleep 0.6
    path = File.join(shots, "#{name}.png")
    if selector
      find(selector, match: :first).native.save_screenshot(path)
    else
      page.save_screenshot(path)
    end
    warn "  [screenshot] #{path}"
  end

  it 'walks Course Settings → Apps → + App → By URL and shows the resulting tab' do
    course_id = provisioned[:canvas_course_id]
    in_canvas do
      ensure_canvas_logged_in_as_instructor
      page.current_window.resize_to(1280, 800)

      visit "/courses/#{course_id}/settings"
      # Canvas's settings tabs are InstUI role=tab divs, not links. The classic
      # "Apps" tab is the one with the By URL dialog; "Apps (New)" is Canvas's
      # newer LTI 1.3 registration UI.
      apps_tab = find('[role="tab"]', text: 'Apps', exact_text: true, wait: 20)
      shoot('01_course_settings')

      apps_tab.click
      # Older Canvas shows the App Center first and needs "View App
      # Configurations"; current Canvas lands straight on "External Apps".
      click_control('View App Configurations') if page.has_button?('View App Configurations',
wait: 3)
      expect(page).to have_content('External Apps', wait: 20)
      expect(page).to have_css('#add-app-button', wait: 20)
      shoot('02_external_apps')

      wait_out_apps_new_crash
      # This Canvas build's Add App dialog is fragile: a configuration-type
      # change re-mounts the form, and a component elsewhere on the settings
      # page (the "Apps (New)" LTI apps list) throws a second or two after the
      # form's state changes, at which point React Router remounts the route
      # and the dialog is gone. Typing field by field never finished before
      # that. So the type is chosen first, then all four fields are set in one
      # DOM write (React-compatible input events) and the capture or the
      # Submit click follows within milliseconds.
      #
      # Pass A: the dialog as an instructor sees it — placeholder credentials
      # and the production config URL.
      open_add_app_dialog
      choose_configuration_type('By URL')
      expect(page).to have_field('Config URL', wait: 15)
      js_fill('Name' => tool_label,
              'Consumer Key' => 'the key from Wiki Education',
              'Shared Secret' => 'the secret from Wiki Education',
              'Config URL' => config_url_shown)
      page.save_screenshot(File.join(shots, '03_by_url_form.png'))
      warn "  [screenshot] #{File.join(shots, '03_by_url_form.png')}"
      dismiss_dialog_if_open
      wait_out_apps_new_crash(timeout: 8)

      # Pass B: the install itself — the dialog's Submit with the deployed
      # staging config and the real key and secret, which never appear in a
      # capture. Confirmed through the API rather than the table, which can
      # keep its pre-submit contents after Canvas's settings page remounts.
      #
      # The dialog's own Submit used to 400 here. The cause was a `domain` in
      # our config XML colliding with the already-installed 1.3 tool; with
      # `domain` dropped, Canvas accepts the dialog's request and the tool is
      # installed by the dialog, exactly as it is for an instructor. The API
      # fallback below stays as a guard: a Canvas-side change that breaks the
      # dialog should not cost the remaining captures, and the warn line says
      # which path was taken.
      open_add_app_dialog
      choose_configuration_type('By URL')
      expect(page).to have_field('Config URL', wait: 15)
      js_fill('Name' => tool_label,
              'Consumer Key' => @credentials['key'],
              'Shared Secret' => @credentials['secret'],
              'Config URL' => config_url_real)
      within(dialog_selector) { click_button 'Submit' }
      expect(page).to have_no_css(dialog_selector, wait: 30)
      tool = eventually(attempts: 8, interval: 2) do
        canvas_api.course_external_tools(course_id:).find { |t| t['url'] == launch_url }
      end
      if tool
        warn "  [course tools] installed by the dialog (id=#{tool['id']})"
      else
        warn '  [course tools] the dialog did not install it; installing through the API'
        canvas_api.install_external_tool(
          course_id:,
          tool_config: { name: tool_label, consumer_key: @credentials['key'],
                         shared_secret: @credentials['secret'],
                         config_type: 'by_url', config_url: config_url_real,
                         verify_uniqueness: true }
        )
        tool = eventually(attempts: 10, interval: 2) do
          canvas_api.course_external_tools(course_id:).find { |t| t['url'] == launch_url }
        end
      end
      expect(tool).to be_truthy
      # Back to the list the way the instructor gets there (a direct visit to
      # the configurations URL opens the settings page on its first tab).
      visit "/courses/#{course_id}/settings"
      find('[role="tab"]', text: 'Apps', exact_text: true, wait: 20).click
      expect(page).to have_css('#external-tools-table tr', text: tool_label, wait: 30)
      shoot('04_app_added')

      visit "/courses/#{course_id}"
      expect(page).to have_link(tool_label, wait: 20)
      shoot('05_course_nav_tab', selector: '#section-tabs, nav#section-tabs')

      click_wiki_education_tab
      frame = settle_canvas_tool_iframe
      expect(frame).to be_truthy
      shoot('06_first_launch')
    end
  end

  # This Canvas build's "Apps (New)" tab component (InstructorApps.tsx) throws
  # a couple of seconds after every visit to the settings page, and the
  # router's error boundary remounts the whole route — taking any open
  # + App dialog with it. Real instructors on this instance would see the
  # dialog vanish too; production Canvas builds may not have the bug. Wait for
  # the crash to land (it shows up in the browser console) before opening the
  # dialog, so the form survives long enough to be filled and submitted.
  def wait_out_apps_new_crash(timeout: 20)
    page.driver.browser.logs.get(:browser) # drain entries from earlier loads
    deadline = Time.now + timeout
    until Time.now > deadline
      entries = page.driver.browser.logs.get(:browser)
      break if entries.any? { |e| e.message.include?('num_pages') }

      sleep 1
    end
    sleep 2 # let the remount settle
  rescue StandardError => e
    warn "  [apps-new crash wait] console unavailable (#{e.message}); waiting blind"
    sleep 8
  end


  # Opening the + App dialog mounts Canvas's LTI apps list, which on this
  # build throws (`num_pages` of undefined) once its fetch returns, and the
  # route remount closes the dialog. Open it, watch the console for that
  # crash, and reopen until an open survives its first seconds.
  def open_add_app_dialog(attempts: 4)
    attempts.times do |i|
      page.driver.browser.logs.get(:browser) # drain
      find('#add-app-button').click
      expect(page).to have_css(dialog_selector, wait: 20)
      crashed = false
      8.times do
        sleep 1
        entries = page.driver.browser.logs.get(:browser)
        crashed = entries.any? { |e| e.message.include?('num_pages') }
        break if crashed || page.has_no_css?(dialog_selector, wait: 0)
      end
      still_open = page.has_css?(dialog_selector, wait: 2)
      warn "  [dialog] open attempt #{i + 1}: crash=#{crashed} still_open=#{still_open}"
      return if still_open

      expect(page).to have_css('#add-app-button', wait: 20)
    end
    raise 'the + App dialog never survived its first seconds'
  end

  # Where the open dialog sits in the window, read off the focused field's
  # nearest dialog-like ancestor, so the full-window shot can be cropped to it.
  def dialog_geometry
    page.evaluate_script(<<~JS)
      (function () {
        var el = document.activeElement;
        var box = el && (el.closest('[role="dialog"], .ReactModal__Content, .ui-dialog, form') || el);
        if (!box) { return null; }
        var r = box.getBoundingClientRect();
        return { tag: box.tagName, role: box.getAttribute('role'), cls: (box.className || '').toString().slice(0, 80),
                 x: Math.round(r.left), y: Math.round(r.top), w: Math.round(r.width), h: Math.round(r.height),
                 dialogs: document.querySelectorAll('[role="dialog"]').length };
      })()
    JS
  end

  # Canvas's classic External Apps dialog (jQuery UI) vs. its React replacement:
  # accept either, since the test instance may be on either side of the change.
  def dialog_selector
    '.ui-dialog:not([style*="display: none"]), [role="dialog"], .ReactModal__Content'
  end

  # A native <select> in the classic dialog; an InstUI combobox (an input with
  # role=combobox and a listbox of role=option items) in the React one.
  def choose_configuration_type(option)
    if page.has_select?('Configuration Type', wait: 2)
      select option, from: 'Configuration Type'
    elsif page.has_css?('#configuration_type_selector', wait: 1)
      find('#configuration_type_selector').select(option)
    else
      find('[role="combobox"]', match: :first).click
      find('[role="option"]', text: option, exact_text: true, wait: 10).click
    end
  end

  # Buttons and links are interchangeable across Canvas versions here.
  def click_control(text)
    if page.has_button?(text, wait: 5)
      click_button text
    else
      click_link text
    end
  end


  # Set several labelled inputs at once through the DOM, the way React expects
  # (the native value setter, then an `input` event), so the whole form changes
  # in one tick instead of one keystroke at a time.
  def js_fill(values)
    result = page.evaluate_script(<<~'JS', values)
      (function (values) {
        var setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
        var done = [];
        Object.keys(values).forEach(function (label) {
          var lab = Array.from(document.querySelectorAll('label')).find(function (l) {
            return l.textContent.trim().replace(/\s*\*$/, '') === label;
          });
          if (!lab) { return; }
          var input = (lab.htmlFor && document.getElementById(lab.htmlFor)) || lab.querySelector('input');
          if (!input) { return; }
          // The browser's own text insertion yields the genuine input events a
          // React controlled input trusts; a bare value assignment plus a
          // synthetic event left Canvas's form state empty and Submit sent nothing.
          input.focus();
          input.select();
          var ok = document.execCommand('insertText', false, values[label]);
          if (!ok || input.value !== values[label]) {
            setter.call(input, values[label]);
            input.dispatchEvent(new Event('input', { bubbles: true }));
          }
          done.push(label);
        });
        return done;
      })(arguments[0])
    JS
    warn "  [js-fill] set #{result.inspect}"
    expect(result.sort).to eq(values.keys.sort)
  end

  def dismiss_dialog_if_open
    return unless page.has_css?(dialog_selector, wait: 3)

    within(dialog_selector) { click_button 'Cancel' }
    expect(page).to have_no_css(dialog_selector, wait: 10)
  rescue Capybara::ElementNotFound
    find('body').send_keys(:escape)
  end

  def by_url_selected?
    page.has_select?('Configuration Type', selected: 'By URL', wait: 0)
  end




  # Replace a field's value with keystrokes only (select-all, then type).
  def set_field(label, value, attempts: 4)
    field = find_field(label, wait: 10)
    field.send_keys([:control, 'a'], :backspace) unless field.value.to_s.empty?
    field.send_keys(value)
  rescue Selenium::WebDriver::Error::StaleElementReferenceError
    raise if (attempts -= 1).zero?

    sleep 0.5
    retry
  end
end
