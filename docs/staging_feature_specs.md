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

### Test-identity bootstrap (Tranche 3+)

The flow specs drive Canvas + the dashboard as a real
instructor (and later, a real student). The browser session
needs to be pre-authenticated for each role, and the Wikipedia
OAuth grant needs to be pre-approved so the launch flow runs
silently.

One-time per profile (re-do if `tmp/staging-browser-profile/` is
deleted):

1. Run `bin/staging-feature-spec spec/staging/canary_spec.rb` to
   create the persistent profile.
2. Open a fresh Chrome instance with that profile, e.g.
   `google-chrome --user-data-dir=tmp/staging-browser-profile`.
3. Log into `canvas.wikiedu.org` as the test instructor user
   (the Canvas user whose id you put in
   `CANVAS_TEST_INSTRUCTOR_USER_ID`). Stay logged in.
4. In the same Chrome window, visit
   `https://dashboard-testing.wikiedu.org/users/auth/mediawiki`
   and complete the Wikipedia OAuth approval for the
   instructor's Wikipedia identity.
5. (For G7+) Repeat steps 3-4 for the test student in a
   separate browser profile — see Tranche 3 docs when those
   specs land.
6. Close that Chrome instance.

The session cookies + OAuth grant now live in the profile and
persist between spec runs.

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

## Layout

```
spec/staging/
├── spec_helper.rb            # staging-specific Capybara + Selenium config
├── canary_spec.rb            # connectivity probe (T1)
├── provisioning_spec.rb      # provisioning-layer smoke test (T2)
├── g2_instructor_launch_spec.rb # instructor launch flow (T3)
└── support/
    ├── sessions.rb           # in_canvas / in_dashboard / switch_to_new_tab helpers
    ├── failure_screenshot.rb # capture screenshots + DOM on spec failure
    ├── dashboard_console.rb  # SSH-based Ruby runner against staging (T2)
    ├── canvas_api_client.rb  # Canvas REST API wrapper (T2)
    ├── dashboard_admin_client.rb # course CRUD via DashboardConsole (T2)
    └── launch_helpers.rb     # Canvas-tab → break-out-iframe DSL (T3)

tmp/
├── staging-browser-profile/  # persistent Chrome user-data-dir (gitignored)
└── staging-failures/         # screenshots + HTML dumps from failed specs (gitignored)

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
