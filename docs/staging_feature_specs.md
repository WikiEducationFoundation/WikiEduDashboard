# Live-staging feature specs — operator guide

The `spec/staging/` suite drives a real Chrome browser against the
deployed staging environment (`dashboard-testing.wikiedu.org` and
`canvas.wikiedu.org`) so we can iterate on the Canvas integration's
end-to-end UX without manual click-throughs.

This is the operator guide. It covers the one-time setup and
day-to-day usage of what's been shipped so far: the harness machinery
plus a connectivity canary spec. Later additions (provisioning
helpers, full smoke-test flows) will be documented here as they land.

## One-time bootstrap

Done once per developer machine. Re-do if the persistent profile is
deleted.

### 1. Confirm prerequisites

You'll need:

- **Chrome** installed locally (Selenium drives it).
- **`chromedriver`** on PATH (Selenium 4+ auto-downloads via
  `selenium-manager` in most environments; if it doesn't,
  `brew install chromedriver` on macOS or download from
  <https://chromedriver.chromium.org/>).

The canary spec doesn't need any credentials. Provisioning specs
(Tranche 2) need a Canvas admin token and SSH access. Flow specs
(Tranche 3+) additionally need test-identity bootstrapping in the
persistent Chrome profile. See the next two sections.

All required values live in a local untracked env file at
`.env.staging-tests`. Copy `.env.staging-tests.example` and fill in
real values; the runner loads it at start-up. Nothing involving
passwords, API tokens, or per-user identities should ever be
checked into this repo.

### Canvas admin token (Tranche 2+)

Generate at: Canvas → Account → Settings → "+ New Access Token",
under a user with admin permissions on `CANVAS_TEST_ACCOUNT_ID`.
Drop into `.env.staging-tests` as `CANVAS_ADMIN_TOKEN=...`.

### Test-identity credentials (Tranche 3+)

The flow specs drive Canvas + Wikipedia logins programmatically
when the persistent Chrome profile doesn't already carry an
active session, so no manual bootstrap is required day-to-day.
For each role (`_INSTRUCTOR_` and `_STUDENT_`), populate in
`.env.staging-tests`:

- `CANVAS_TEST_<ROLE>_USER_ID` — Canvas user id (from
  `GET /api/v1/users/self` with that user's token, or visit the
  profile page and read the URL).
- `CANVAS_TEST_<ROLE>_LOGIN` — Canvas login id (email or
  username, whatever the user types into the Canvas login form).
- `CANVAS_TEST_<ROLE>_PASSWORD` — Canvas password.
- `WIKIPEDIA_TEST_<ROLE>_USERNAME` — Wikipedia account username.
  Must already have (or be willing to create) a `User` row on
  `dashboard-testing.wikiedu.org` (created automatically on
  first Wikipedia OAuth login).
- `WIKIPEDIA_TEST_<ROLE>_PASSWORD` — Wikipedia password.

**The first-ever run on a fresh profile needs a human watching the
headed browser.** The login helper types the Wikipedia username +
password, but Wikipedia commonly then demands an **email confirmation
code** (you paste it in) and shows the **OAuth "Allow"** page once per
(user, application) pair — the helper clicks Allow if it catches it in
time, but on a slow first login you may need to click it yourself. Once
through, Wikipedia remembers the session + grant and the persistent
profile carries them, so **subsequent runs are fully silent.** Budget a
couple of manual minutes the first time (and after any profile reset);
the spec's content waits may time out while you're entering the code, so
just re-run once the profile is warm.

Day-to-day runs only re-authenticate when the persistent profile
has lost the session (cookies expired, profile reset, etc.), so
having the credentials in env keeps the harness self-sufficient.

#### Two browser profiles

There are two persistent Chrome profiles, one per persona:

- `tmp/staging-browser-profile/` — the **instructor** profile, used by
  every spec (`:staging_chrome` driver, the default).
- `tmp/staging-browser-profile-student/` — the **student** profile,
  used only by G7's student-launch walk (`:staging_chrome_student`
  driver, entered via the `in_student_browser` helper).

Two directories because some flows need the instructor and the student
logged into Canvas — and granted Wikipedia OAuth — at the same time,
and Chrome refuses to share one `--user-data-dir` between two live
processes. The student profile bootstraps itself on the first G7 run
(the login helpers drive the student's Canvas login + Wikipedia OAuth
"Allow" using the `_STUDENT_` credentials), exactly like the
instructor profile did.

### 2. Run the canary

```sh
bin/staging-feature-spec spec/staging/canary_spec.rb
```

A visible Chrome window will open, navigate to
`dashboard-testing.wikiedu.org`, then to `canvas.wikiedu.org`. Three
specs should pass. The Chrome profile directory created at
`tmp/staging-browser-profile/` persists between runs and is
gitignored under the project's `/tmp` rule.

## Day-to-day usage

```sh
bin/staging-feature-spec spec/staging/canary_spec.rb            # one spec
bin/staging-feature-spec spec/staging/                          # all staging specs

HEADLESS=1 bin/staging-feature-spec spec/staging/canary_spec.rb # no visible browser
```

Default is HEADED — visible browser, because the whole point is
visual iteration. Set `HEADLESS=1` if you're running over SSH or
just want quieter output.

The standard `bundle exec rspec` invocation does NOT pick up
`spec/staging/`: `spec/spec_helper.rb` adds
`filter_run_excluding :staging` plus a `define_derived_metadata`
rule that auto-tags everything in `spec/staging/`. CI never runs
these specs.

## Smoke-test flows (Tranche 3)

The smoke test as a re-runnable suite. Each spec provisions a fresh
Canvas course + dashboard course, runs its slice, and tears both down
on completion (pass or fail), so re-runs are hermetic.

```sh
bin/staging-feature-spec spec/staging/g3_nrps_roster_sync_spec.rb
bin/staging-feature-spec spec/staging/g7_student_first_launch_spec.rb
bin/staging-feature-spec spec/staging/g8_score_push_spec.rb
bin/staging-feature-spec spec/staging/g9_exercise_sandbox_spec.rb
```

- **g2** — instructor first launch → bind → land on `/courses/<slug>`.
- **g3** — after binding, an NRPS roster sync surfaces the
  Canvas-enrolled student as a deferred (Wikipedia-unlinked)
  `LtiContext`, while the instructor stays linked.
- **g7** — the real student first-launch walk (two browser personas):
  the instructor binds the course, then the student completes Wikipedia
  OAuth in their own profile and is auto-enrolled as a `STUDENT`.
- **g8** — completing a training module for a linked student pushes a
  `1.0` to the "Wikipedia trainings" Canvas column with an
  "X of Y trainings completed" comment.
- **g9** — completing an exercise pushes a `1.0` to the exercise's
  column with the student's sandbox URL in the comment.

Every spec needs at least one real instructor launch (that's what
captures the LTIAAS `service_key` the background sync jobs run on), so
none of them are pure API/console flows.

**Run G7 at least once before G8 / G9.** G8 and G9 enroll the student
on the Canvas side and link them via console (bypassing the browser
walk that G7 owns), but the *dashboard* User behind the student's
Wikipedia account only exists after a real OAuth login. G7's student
launch creates it; until then G8/G9 skip with a clear message.

These flows have side effects on the live Canvas instance (they create
and delete courses, post scores) and drive real Wikipedia OAuth, so
they're a local, operator-run loop — never CI.

## UX screenshots

Two specs walk the integration and save PNGs at named moments, so the
team can review the actual per-role experience without clicking through
it. They provision + tear down their own state, same as the flow specs.

```sh
bin/staging-feature-spec spec/staging/instructor_setup_screenshots_spec.rb
bin/staging-feature-spec spec/staging/student_screenshots_spec.rb
```

- **`instructor_setup_screenshots_spec.rb`** →
  `.claude/canvas_integration/canvas_integration_instructor_guide/screenshots/`:
  Canvas course w/ tab, in-iframe landing, the empty setup view, course
  selected, the bound course page, and the instructor's
  LmsIntegrationStatus (StaffView) panel.
- **`student_screenshots_spec.rb`** →
  `.claude/canvas_integration/screenshots/student/`: in-iframe landing,
  post-OAuth enrollment landing, the student's LmsIntegrationStatus
  (StudentView) panel, the `setup_pending` view (instructor hasn't linked
  a course), and the `enrollment_pending_approval` view (course not yet
  approved).

`save_screenshot_to` / `scroll_into_view` live in
`support/screenshots.rb`. Screenshots land under `.claude/` (tracked), so
review the diff before committing — they may contain test fixture names.

### Surfaces not yet auto-captured

These are part of the UX but aren't captured yet, each for a concrete
reason — worth picking up if we want exhaustive coverage:

- **`oauth_redirect` interstitial** ("Continuing to Wikipedia sign-in…")
  — its JS auto-submits on render, so there's no stable moment to shoot.
  Would need JS disabled or a submit-intercept.
- **`enrollment_error` view** — only renders on a JoinCourse failure
  *other* than not-yet-approved (withdrawn / disallowed / invalid sync);
  no clean way to force one of those states on staging yet.
- **Admin's LmsIntegrationStatus panel** (StaffView without the LMS
  link) — needs a dashboard *admin* identity in `.env.staging-tests`
  (current creds are instructor + student only).
- **Canvas-side gradebook + student grades pages** — the columns and
  scores G8/G9 push. These are Canvas's own SPA; readable via the REST
  API (which G8/G9 assert on) but DOM-scraping them for a screenshot is
  fragile. Capturable, but deferred.

## Layout

```
spec/staging/
├── spec_helper.rb            # staging-specific Capybara + Selenium config (2 drivers)
├── canary_spec.rb            # connectivity probe (T1)
├── provisioning_spec.rb      # provisioning-layer smoke test (T2)
├── g2_instructor_launch_spec.rb  # instructor launch flow (T3)
├── g3_nrps_roster_sync_spec.rb   # roster sync surfaces the student (T3)
├── g7_student_first_launch_spec.rb # student OAuth → auto-enroll (T3)
├── g8_score_push_spec.rb         # training completion → gradebook 1.0 (T3)
├── g9_exercise_sandbox_spec.rb   # exercise completion → 1.0 + sandbox URL (T3)
├── instructor_setup_screenshots_spec.rb # instructor UX screenshots
├── student_screenshots_spec.rb   # student UX screenshots (landing/panel/pending states)
└── support/
    ├── sessions.rb           # in_canvas / in_dashboard / in_student_browser helpers
    ├── failure_screenshot.rb # capture screenshots + DOM on spec failure
    ├── screenshots.rb        # save_screenshot_to / scroll_into_view for screenshot specs
    ├── polling.rb            # `eventually` retry for Canvas grade-passback lag (T3)
    ├── dashboard_console.rb  # SSH-based Ruby runner against staging (T2)
    ├── canvas_api_client.rb  # Canvas REST API wrapper (T2; assignments/submissions in T3)
    ├── dashboard_admin_client.rb # course/timeline/sync state-shaping via DashboardConsole
    ├── launch_helpers.rb     # Canvas-tab → break-out-iframe → bind DSL (T3)
    └── login_helpers.rb      # Canvas + Wikipedia form-driven login (T3)

tmp/
├── staging-browser-profile/         # persistent instructor Chrome profile (gitignored)
├── staging-browser-profile-student/ # persistent student Chrome profile (gitignored)
└── staging-failures/                # screenshots + HTML dumps from failed specs (gitignored)

bin/staging-feature-spec      # the runner
```

## Troubleshooting

**"chromedriver not found"** — Install via `selenium-manager`
(bundled with `selenium-webdriver` 4.11+),
`brew install chromedriver` on macOS, or download from
<https://chromedriver.chromium.org/>.

**"net::ERR_CONNECTION_REFUSED" or 502 from staging** — The
dashboard-testing or `canvas.wikiedu.org` host may be down /
deploying. Check with
`curl -I https://dashboard-testing.wikiedu.org`.

**Browser opens but the spec fails with "expected ... to have
content X"** — Look at the screenshot the harness saved under
`tmp/staging-failures/<spec_description>/` to see what was actually
on the page.

**The browser opens but the spec fails immediately on first run** —
You may have a stale profile. Delete `tmp/staging-browser-profile/`
and re-run.

**The visible browser disappears too fast to see anything** — The
canary spec finishes in seconds because it doesn't interact with
the page much. Add `sleep N` temporarily inside the spec while
iterating, the way the dashboard's regular feature specs do.

**"can't share a profile while another Chrome instance is using
it"** — Close any other Chrome window that's also using
`tmp/staging-browser-profile/`. Each `bin/staging-feature-spec`
invocation opens its own browser; don't run two simultaneously.

**Spec can't select the course in the setup dropdown, or can't find
the `.lms-integration-status` panel** — staging is almost certainly
running **older code than this branch**. These specs assume staging is
deployed from the same commit: the setup dropdown labels its options by
course *slug* (older builds used the bare title), and the LMS-status
panel only exists from the panel commit onward. Redeploy the branch to
staging (`git push origin <branch>:staging && cap staging deploy`) so
the deployed UI matches the specs, then re-run. The captured page under
`tmp/staging-failures/` shows which UI you actually got.
