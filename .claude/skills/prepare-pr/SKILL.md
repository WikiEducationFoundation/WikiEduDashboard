---
name: prepare-pr
description: Prepare a pull request description for the current branch following the WikiEduDashboard PR template. Use this skill when asked to prepare a PR, draft a PR description, or get a branch ready to open as a pull request.
---

# PR Description Preparer

Draft a complete pull request description for the current branch, following the project's
`PULL_REQUEST_TEMPLATE.md` and `docs/ai_guidelines.md`.

## Phase 0: Clean up previous iteration

Run `bin/pr-screenshots --clean` to remove any leftover screenshots and draft
from a prior run before starting fresh.

## Phase 1: Understand the branch

Gather the raw material:

1. `git log master..HEAD --oneline` — list all commits
2. `git log master..HEAD --format="%H %ai %s"` — commits with timestamps (for estimating elapsed time and effort)
3. `git log master..HEAD` — full commit messages (for design decisions and process notes)
4. `git diff master...HEAD --stat` — which files changed and how much
5. Read `PULL_REQUEST_TEMPLATE.md` — know the exact sections required

From the timestamps, estimate:
- **Elapsed calendar time**: from the first commit's date to the last
- **Human effort level**: was this done in one sitting (< 1 hour), a few sessions (a day or two), or spread over many days? A large number of commits across many days suggests sustained iteration; a handful of commits within minutes suggests a single focused AI-assisted session.

## Phase 2: Capture screenshots

There are two strategies, and picking the right one for the PR matters a lot
more than picking the right script invocation.

### Strategy A — Disposable screenshot spec (preferred for new features)

For any PR that introduces substantial new UI, write a dedicated feature spec
whose only job is to drive the feature through its interesting states and
save named PNGs. This gives you complete control over what's shown, lets you
seed realistic-looking fixture data, and produces screenshots with stable,
descriptive filenames.

Put it next to the regular specs:
  `spec/features/<feature>_screenshots_spec.rb`

A minimal template:

```ruby
require 'rails_helper'

# `if: ENV['SCREENSHOT']` keeps this spec out of the default suite — it
# only defines itself when bin/pr-screenshots sets the env var.
describe '<Feature> screenshots', type: :feature, js: true,
         if: ENV['SCREENSHOT'] do
  let(:admin) { create(:admin) }
  let(:screenshot_dir) { Rails.root.join('tmp', 'screenshots', ENV['SCREENSHOT']) }

  before do
    FileUtils.mkdir_p(screenshot_dir)
    page.current_window.resize_to(1440, 1000)
    login_as(admin)
  end

  def shoot(name)
    sleep 0.2 # let transitions settle
    page.save_screenshot(screenshot_dir.join("#{name}.png"))
  end

  it 'captures the full UI' do
    # seed whatever looks realistic
    visit '/the/feature'
    shoot('01_landing')

    click_button 'Open editor'
    shoot('02_editor_default')

    # keep going through every state worth showing
  end
end
```

Key conventions:

- **Gate with `if: ENV['SCREENSHOT']`** so the describe block only exists
  when `bin/pr-screenshots` invokes rspec (it sets `SCREENSHOT=before` or
  `SCREENSHOT=after`). The main suite runs zero examples from the file.
  No global RSpec config change needed.
- **Write to `tmp/screenshots/$SCREENSHOT/`** so `bin/pr-screenshots` can
  pair up before/after PNGs by filename on a later run.
- **Name files by stable sort order** (`01_`, `02_`, …) so they appear
  in the intended order in the PR description.
- **Seed fixture data that looks real**, not `foo`/`bar`. Reviewers
  read screenshots.

Then run:
  `bin/pr-screenshots spec/features/<feature>_screenshots_spec.rb`

For a brand-new feature, the spec doesn't exist on master so the before
column will render as `_(did not exist on master)_` automatically. That's
the right outcome — there is no "before" state for something that didn't
exist. For iterations on an existing UI, commit the spec on master first
(or a preceding PR) so the before pass has something to run.

### Strategy B — Auto-detected feature specs

If you're making a small tweak and an existing feature spec already ends up
in a good-looking state at one of its assertion points, you can skip writing
a dedicated spec and let `bin/pr-screenshots` auto-detect:

  `bin/pr-screenshots`   # no arguments

It picks feature specs from files changed in `git diff master...HEAD`,
captures their terminal UI state on both branches, and prints a before/after
markdown snippet.

This works best when:
- The feature spec's final assertion lands on a useful UI state
- You just want a quick confirmation of a visual change, not a walkthrough

It works poorly when:
- The spec ends on something generic like "navigate to X and assert Y has
  content" — the screenshot is whatever happened to be on screen after the
  last `expect`, which is often a narrow slice of the feature
- The spec covers multiple states you'd want to show separately

### Notes for either strategy

- Screenshot files get sanitized by `bin/pr-screenshots` (strips `(`, `)`,
  `→`, and collapses `--` sequences) so they survive as markdown alt text.
- The markdown snippet printed by the script uses paths relative to `tmp/`
  (e.g. `screenshots/after/01_landing.png`) to match where
  `tmp/pr_description.md` lives.
- If there are no UI changes at all (pure backend or config PR), skip this
  phase and put "No UI changes" in the Screenshots section of the
  description.

## Phase 3: Draft the description

Write the full PR description to `tmp/pr_description.md` (create or overwrite).
Fill in every section of the template:

### What this PR does

- Summarize the purpose in 2–4 sentences — what problem it solves and how
- If commits reference GitHub issues (e.g. `#1234`), link them: `Addresses #1234`
- If there are relevant external docs (API docs, gem docs, Wikipedia policies), link them

### AI usage

Inspect the commit messages for signs of AI involvement:
- "Co-Authored-By: Claude" — AI wrote or substantially drafted the code
- "(Commit message written by Claude Code.)" — AI wrote the commit message
- "## Process" sections in commit bodies — read these for how AI was used

Write an honest, specific statement. This project requires transparency. If Claude Code
wrote most of the code under human direction, say so clearly. Name the tool (Claude Code),
describe what it did (drafted code, wrote commit messages, iterated on design), and note
what the human contributed (direction, review, decisions about what to build).

Note that the "What this PR does" summary and other analysis in the description were
also drafted by Claude Code and may contain errors.

Include a brief note on the scale of effort: how many commits, over what time span, and
roughly what that implies about how much human time was involved. For example: "This was
developed across 8 commits over 3 days" or "All commits were made within a single 20-minute
session." This helps reviewers calibrate how much iteration and review went into the work.

Always end the AI usage section with a sentence noting that this PR description was drafted
using a Claude Code skill (`/prepare-pr`).

### Screenshots

Paste the markdown snippet from `bin/pr-screenshots` output directly into this section.
The script outputs before/after tables; use that output as-is.

If screenshots could not be captured (e.g. spec infrastructure issue), describe what the
user should capture manually and which URLs to visit.

### Open questions and concerns

- Surface any tradeoffs or rough edges mentioned in commit messages
- Note anything left out of scope, or follow-up work that might be needed
- If there's nothing notable, write "None." — don't invent concerns

## Phase 4: Preview locally and open the PR

Run `code tmp/pr_description.md` to open the file in VS Code and tell the user to press
Ctrl+Shift+V to preview it with screenshots rendered locally.

When ready to publish, run `bin/open-pr` once. It will:

1. Find each `screenshots/…` reference in `tmp/pr_description.md`.
2. Build an orphan commit containing those files and force-push it to
   `refs/heads/pr-screenshots/<current-branch>` on origin.
3. Rewrite the description to reference each screenshot by its
   `raw.githubusercontent.com` URL on that orphan branch.
4. Create (or update, if the branch already has an open PR) a draft PR with
   the full rewritten description.

The result: a draft PR with screenshots rendered inline, in a single pass,
with no manual drag-and-drop.

**Authentication** is tried in this order:
1. `GITHUB_TOKEN` env var
2. `gh auth token` output, if the GitHub CLI is installed and logged in

If neither is available, the script prints instructions for generating a
classic PAT with `repo` scope.
