# frozen_string_literal: true

# Form-driven login helpers for Canvas + Wikipedia. These run only when
# the persistent Chrome profile doesn't already carry an active
# session — `ensure_canvas_logged_in` and `complete_wikipedia_oauth_if_needed`
# both detect the live state first and no-op when it's already
# authenticated. Day-to-day spec re-runs stay fast.
#
# First-ever spec run (on a fresh profile) drives the full login
# sequence: Canvas pseudonym form → Wikipedia user-login form →
# Wikipedia OAuth "Allow" page. Canvas + Wikipedia remember the login,
# and Wikipedia remembers the OAuth grant per (user, application);
# subsequent runs walk through silently.
#
# TODO markers below mark the selectors most likely to need verifying
# on first real run against staging.
module LoginHelpers
  # Ensure the current Capybara session is logged into Canvas as the
  # test instructor. Assumes we're inside an `in_canvas` block.
  def ensure_canvas_logged_in_as_instructor
    ensure_canvas_logged_in(
      login: ENV.fetch('CANVAS_TEST_INSTRUCTOR_LOGIN'),
      password: ENV.fetch('CANVAS_TEST_INSTRUCTOR_PASSWORD')
    )
  end

  def ensure_canvas_logged_in_as_student
    ensure_canvas_logged_in(
      login: ENV.fetch('CANVAS_TEST_STUDENT_LOGIN'),
      password: ENV.fetch('CANVAS_TEST_STUDENT_PASSWORD')
    )
  end

  # During the LTI launch's OAuth bounce, if Wikipedia shows a login
  # form or an OAuth-approval page, drive them automatically. Falls
  # through silently when the session + grant are already in place.
  def complete_wikipedia_oauth_if_needed(role: :instructor)
    username, password = wikipedia_credentials_for(role)
    fill_wikipedia_login_form_if_present(username, password)
    click_oauth_allow_if_present
  end

  private

  def ensure_canvas_logged_in(login:, password:)
    visit '/login/canvas'
    # Logged in → Canvas redirects to dashboard root, no login form.
    return unless page.has_field?('pseudonym_session[unique_id]', wait: 3)

    fill_in 'pseudonym_session[unique_id]', with: login
    fill_in 'pseudonym_session[password]', with: password
    # The form's submit is `<input name="commit" value="Log In">`; click
    # by `name` to avoid ambiguous matches with any other "Log In" text
    # on the page (e.g., alternate-provider buttons).
    find('input[name="commit"]').click

    # On success Canvas redirects away from /login/canvas. On failure it
    # rerenders the form, often with a flash error visible. Surface that
    # explicitly so the test doesn't cascade into a confusing
    # "nav not found" failure later on.
    return if page.has_no_field?('pseudonym_session[unique_id]', wait: 10)

    flash = first('.ic-flash-error, .ic-flash-warning, .alert', minimum: 0)
    raise "Canvas login as #{login.inspect} failed; " \
          "URL=#{page.current_url} flash=#{flash&.text.inspect}"
  end

  def fill_wikipedia_login_form_if_present(username, password)
    return unless page.has_field?('wpName', wait: 2)

    fill_in 'wpName', with: username
    fill_in 'wpPassword', with: password
    # TODO: confirm Wikipedia's submit-button name. Could be a `<button>`
    # with text "Log in" / "Continue", or an `<input type="submit">`.
    click_button 'Log in'
  end

  def click_oauth_allow_if_present
    # OAuth approval page has an "Allow" / "Accept" button; only
    # appears the first time per (user, application) pair, and
    # Wikipedia remembers thereafter. Wait briefly in case the
    # redirect chain hasn't settled yet.
    return unless page.has_button?('Allow', wait: 3) || page.has_button?('Accept', wait: 1)

    if page.has_button?('Allow')
      click_button 'Allow'
    else
      click_button 'Accept'
    end
  end

  def wikipedia_credentials_for(role)
    case role
    when :instructor
      [ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_USERNAME'),
       ENV.fetch('WIKIPEDIA_TEST_INSTRUCTOR_PASSWORD')]
    when :student
      [ENV.fetch('WIKIPEDIA_TEST_STUDENT_USERNAME'),
       ENV.fetch('WIKIPEDIA_TEST_STUDENT_PASSWORD')]
    else
      raise ArgumentError, "unknown role #{role.inspect}"
    end
  end
end
