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
    settle_oauth_redirect
    raise_on_wikipedia_challenge!
    fill_wikipedia_login_form_if_present(username, password)
    click_oauth_allow_if_present
  end

  private

  # The break-out tab runs through several OAuth redirects (connect_course
  # → oauth_redirect auto-POST → MediaWiki → auth.wikimedia.org) before it
  # settles on a Wikipedia login page, an OAuth "Allow" page, or back on
  # the dashboard. Poll until one of those is in view (or until Wikipedia
  # throws a FancyCaptcha or EmailAuth interstitial, which we surface to
  # the caller). Without polling, a fixed short wait races the chain and
  # skips past the login form while it's still mid-flight.
  def settle_oauth_redirect(timeout: 30)
    deadline = Time.now + timeout
    until Time.now > deadline
      return if page.has_field?('wpName', wait: 0)
      return if oauth_allow_present?
      return if page.current_url.include?('dashboard-testing.wikiedu.org')
      return if captcha_challenge_present? || emailauth_challenge_present?

      sleep 0.5
    end
  end

  def oauth_allow_present?
    page.has_button?('Allow', wait: 0) || page.has_button?('Accept', wait: 0)
  end

  # FancyCaptcha (Wikimedia's home-grown image captcha) re-renders on the
  # same Special:UserLogin form when a recent badlogin counter trips —
  # `$wgCaptchaBadLoginAttempts` (default 3 per IP / 5 min) or
  # `$wgCaptchaBadLoginPerUserAttempts` (default 20 per user / 10 min).
  # The container + word input are the canonical markers from ConfirmEdit.
  def captcha_challenge_present?
    page.has_css?('.fancycaptcha-captcha-container', wait: 0) ||
      page.has_field?('wpCaptchaWord', wait: 0)
  end

  # Wikimedia's EmailAuth second-step form is a single `name="token"`
  # input — distinct from the primary login form (no `wpName` /
  # `wpPassword`). Triggered when LoginNotify can't find a known-device
  # marker (cookie or server-side row), so a fresh Chrome profile hits
  # this every time until a successful "Keep me logged in" run plants
  # `loginnotify_prevlogins`.
  def emailauth_challenge_present?
    page.has_field?('token', wait: 0) && page.has_no_field?('wpName', wait: 0)
  end

  # Stop the spec with a clear explanation instead of silently retrying
  # (each retry submits the now-broken form, advances the badlogin
  # counter, and digs the lockout deeper — exactly the trap the
  # Wikimedia research agent flagged).
  def raise_on_wikipedia_challenge!
    if captcha_challenge_present?
      raise 'Wikipedia FancyCaptcha appeared on login — usually a recent ' \
            'failed login from this IP tripped the badlogin counter (default ' \
            "300s window). Wait a few minutes and retry, or log in once " \
            "manually with 'Keep me logged in' checked to refresh the " \
            'loginnotify_prevlogins cookie so future runs stay silent.'
    end
    return unless emailauth_challenge_present?

    raise 'Wikipedia EmailAuth code prompt appeared (login from an ' \
          "unrecognized device). Enter the code manually once with 'Keep " \
          "me logged in' checked so the profile keeps loginnotify_prevlogins " \
          'for ~180 days; subsequent runs will be silent.'
  end

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
    return unless page.has_field?('wpName', wait: 0)

    fill_in 'wpName', with: username
    fill_in 'wpPassword', with: password
    # Persist the login across browser-process restarts ("Keep me logged
    # in for up to one year") so subsequent spec runs reuse the session
    # and the OAuth bounce stays silent. Without it the session cookie is
    # cleared when the run's browser closes, forcing a fresh login — and
    # an interactive email-confirmation challenge — every run.
    check 'wpRemember' if page.has_field?('wpRemember', wait: 0)
    click_button 'Log in'
    # Submitting resumes the OAuth chain toward the grant; let it settle
    # so a follow-on "Allow" page (or the dashboard) is in view next.
    settle_oauth_redirect
    # A post-submit challenge means the password attempt failed or the
    # device wasn't recognized — fail loudly rather than spin forward.
    raise_on_wikipedia_challenge!
  end

  def click_oauth_allow_if_present
    # OAuth approval page has an "Allow" / "Accept" button; only appears
    # the first time per (user, application) pair, then Wikipedia
    # remembers the grant. settle_oauth_redirect already waited for it.
    return unless oauth_allow_present?

    page.has_button?('Allow') ? click_button('Allow') : click_button('Accept')
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
