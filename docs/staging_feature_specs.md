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

No authentication credentials are required for the canary spec —
it doesn't touch Canvas or trigger any auth flow. Later flow specs
(when they land) will require Canvas and Wikipedia test identities
whose credentials live in a local untracked env file at
`.env.staging-tests` (which the runner will read at start-up).
Nothing involving passwords, API tokens, or per-user identities
should be checked into this repo.

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
├── canary_spec.rb            # connectivity probe
└── support/
    ├── sessions.rb           # in_canvas / in_dashboard / switch_to_new_tab helpers
    └── failure_screenshot.rb # capture screenshots + DOM on spec failure

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
