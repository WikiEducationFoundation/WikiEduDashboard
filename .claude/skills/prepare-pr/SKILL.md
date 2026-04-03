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
2. `git log master..HEAD` — full commit messages (for design decisions and process notes)
3. `git diff master...HEAD --stat` — which files changed and how much
4. Read `PULL_REQUEST_TEMPLATE.md` — know the exact sections required

## Phase 2: Capture screenshots

Run `bin/pr-screenshots` (no arguments — it auto-detects affected specs from the diff).
This script will:
- Run the relevant feature specs on the current branch to capture "after" screenshots
- Stash changes, checkout master, run the same specs for "before" screenshots, restore
- Sanitize screenshot filenames (strips `(`, `)`, `→`, and other markdown-breaking chars)
- Print a markdown snippet at the end with before/after tables — save this for Phase 3

Image paths in the snippet are relative to `tmp/` (e.g. `screenshots/before/foo.png`),
matching where `tmp/pr_description.md` will live.

If the script finds no specs automatically, pass the relevant spec file(s) explicitly:
  `bin/pr-screenshots spec/features/foo_spec.rb`

If there are no UI changes (pure backend or config-only PRs), skip this phase and note
"No UI changes" in the Screenshots section.

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

## Phase 4: Open and confirm

Run `code tmp/pr_description.md` to open the file in VS Code, then tell the user it's
ready and to press Ctrl+Shift+V (or click the preview icon) to open the markdown preview.
