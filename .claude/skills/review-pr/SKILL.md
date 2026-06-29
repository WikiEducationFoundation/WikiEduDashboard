---
name: review-pr
description: Walk through a structured PR review workflow. Use this skill when reviewing a pull request, triaging PRs, or starting a code review.
---

# Review PR

A structured workflow for reviewing pull requests. Claude surfaces
information and runs commands; the reviewer makes all judgments.

Invoke as `/review-pr` (to list open PRs) or `/review-pr 6797` (specific PR).

---

## Phase 1: Select and orient

If a PR number was given as `$ARGUMENTS`, use it. Otherwise:

```bash
gh pr list --state open --json number,title,author,createdAt,additions,deletions,changedFiles --template '{{range .}}#{{.number}}  {{.title}}  ({{.author.login}}, +{{.additions}}/−{{.deletions}}, {{.changedFiles}} files, {{timeago .createdAt}}){{"\n"}}{{end}}'
```

Ask the reviewer which PR to review.

Once a PR is selected, gather orientation in parallel:

1. **PR metadata and description:**
   ```bash
   gh pr view <number> --json title,author,body,labels,createdAt,headRefName,baseRefName,statusCheckRollup
   ```

2. **CI status** — summarize pass/fail/pending from `statusCheckRollup`.

3. **Changed files overview:**
   ```bash
   gh pr diff <number> --name-only
   ```

4. **Diff size** (use `diffstat` or pipe through `wc`; `gh pr diff`
   does not support `--stat`):
   ```bash
   gh pr diff <number> | diffstat
   ```

Present a concise orientation summary: what the PR does (from the
description), who wrote it, CI status, and scope (files/lines changed).

### Re-review detection

After gathering orientation, check for existing reviews from us:
```bash
gh api repos/WikiEducationFoundation/WikiEduDashboard/pulls/<number>/reviews \
  --jq '[.[] | select(.user.login == "ragesoss")] | sort_by(.submitted_at) | last | {state, submitted_at: .submitted_at, commit_id: .commit_id}'
```

Also fetch our prior review comments and PR comments:
```bash
gh api repos/WikiEducationFoundation/WikiEduDashboard/pulls/<number>/comments \
  --jq '[.[] | select(.user.login == "ragesoss")] | .[].body'
gh pr view <number> --json comments --jq '.comments[] | select(.author.login == "ragesoss") | .body'
```

If a prior review exists, compare the review's `commit_id` against the
current HEAD of the PR branch. If there are new commits after the
reviewed commit, this is a **re-review**. Switch to the re-review
workflow (below) instead of Phases 2–5.

If there is no prior review from us, proceed to Phase 2 as normal.

---

## Phase 2: Quick triage

The goal is to catch issues worth flagging early, before investing in a
deep review. Check each of the following and report findings clearly.

### PR template and description
- Does the description explain what the PR does and why?
- Does it reference an issue number?
- For UI changes: are there screenshots or a description of visual changes?
- Is the PR marked `[WIP]`? If so, note it — may not be ready for review.

### CI status
- Are checks passing, failing, or still running?
- If failing, what failed? (Summarize from `statusCheckRollup` or link.)

### Test coverage
- Do the changed files include corresponding spec changes?
- If new functionality was added without tests, flag it.

### Prior feedback
Check whether the author has earlier related PRs (closed or open) with
review comments from the reviewer:
```bash
gh pr list --author <login> --state closed --limit 10 --json number,title,additions
```
If a large or related prior PR exists, fetch its review comments with
`gh api repos/.../pulls/<number>/comments` and summarize any feedback
that is still relevant to the current PR.

### Summary
Present triage findings as a checklist. Ask the reviewer:

> Any of these worth sending quick feedback on before continuing, or
> should we proceed to the full review?

If the reviewer wants to send early feedback, help them draft a comment
(see "Posting review comments" below for tone/attribution rules), then
stop or continue as directed.

---

## Phase 3: Get the code locally

Check out the PR to a local review branch:
```bash
gh pr checkout <number> --branch review/<number>
```

If there are local uncommitted changes, stash or warn before
proceeding.

Merge current master into the review branch so that testing happens
against the latest code, not just the PR's base:
```bash
git merge master --no-edit
```

If there are merge conflicts, report them to the reviewer.

If the PR adds or changes JS dependencies (`package.json` changed),
run `yarn install`. Always run `yarn build` and confirm it succeeds
without errors — a broken build is itself a review finding. If the
build fails, report the errors before continuing.

### Baseline: run existing specs for affected areas

Before writing any new specs, run existing specs that cover the same
area as the PR. This establishes whether the PR introduces
regressions in previously-passing tests.

Identify affected spec files by mapping changed files to their specs:
- `app/controllers/foo_controller.rb` → `spec/controllers/foo_controller_spec.rb`
- `app/presenters/foo_presenter.rb` → `spec/presenters/foo_presenter_spec.rb`
- `app/views/foo/bar.html.haml` → `spec/features/*foo*` or `spec/features/*bar*`
- `app/services/foo.rb` → `spec/services/foo_spec.rb`

Also include any spec the PR itself modifies. Run them all:
```bash
bundle exec rspec <affected_spec_files>
```

Compare results to master if any fail — check out master, run the
same specs, and report whether failures are pre-existing or
PR-introduced. PR-introduced failures are review findings with the
same weight as bugs found in code review.

---

## Phase 4: Exploratory specs and demo

For PRs with user-facing changes, write exploratory feature specs
that exercise the new functionality. Exploratory specs serve three
purposes: verifying the feature works, giving the reviewer a visual
demo, and — when code-reading has surfaced a suspected behavior
change — converting that reasoned finding into reproducible fact. A
spec that exercises the contrasting cases (before/after,
affected/unaffected) turns an argument about code paths into a
demonstration the author can rerun. When a spec serves this third
purpose, consider including it in the review comment (or linking to
it) so the finding is harder to dismiss. (The reviewer can skip the
exploratory spec entirely if the PR is trivial, but the default is
to write one.)

1. Read the changed views, controllers, and presenters to understand
   what the feature does.
2. Write a temporary spec file (`spec/features/<descriptive>_spec.rb`)
   with focused examples covering the key user flows and edge cases.
   **Seed with production-realistic data shapes**, not minimal or
   arbitrary values: a spec that passes against integer seeds like
   `1000` can hide a bug that only fires against the comma-formatted
   strings production actually stores. This matters most when the PR
   touches input types, validation, serialization, or display
   formatting. Sources for realistic shapes: existing factories and
   fixtures, `db/seeds.rb`, other specs that exercise the same model,
   or — if none of those is conclusive — ask the reviewer.
3. Run the specs headless first to get them passing:
   ```bash
   bin/feature-spec spec/features/<file>_spec.rb
   ```
4. Fix any spec issues. If specs fail due to actual bugs in the PR
   code, note them — these are review findings.
5. Once specs are green (or failures are confirmed bugs), offer to
   run headed so the reviewer can watch:
   ```bash
   HEADED=1 bin/feature-spec spec/features/<file>_spec.rb
   ```

The exploratory spec can also be shared with the PR author if useful.

For purely backend PRs, write unit specs instead of feature specs if
the PR's own spec coverage is thin. The same three purposes apply,
especially the third — a contrasting-cases unit spec is just as
useful for pinning down a suspected behavior change. For
configuration-only or trivial changes, skip to Phase 5.

---

## Phase 5: Code review

Run linters on the checked-out branch:
```bash
# Ruby files changed in the PR
bundle exec rubocop <changed .rb files>
# JS/JSX files changed in the PR
yarn eslint <changed .js/.jsx files>
```

### Migration safety check

If the PR diff includes any file in `db/migrate/`, work through this
checklist explicitly before continuing the rest of the review. Reach a
clear verdict on in-deployment viability before moving on; if anything
is unknown (DB version, table size, etc.), ask the reviewer rather than
glossing over it.

- **Shape.** Additive (add column, add table, new index) is safer than
  changing or destructive (drop, rename, change column, add NOT NULL on
  populated column). For `add_column`, nullable + literal default is
  the textbook safe form.
- **Backfill.** Does the migration run an inline `update_all`, `each`,
  or `find_each` over rows? Inline backfills hold the migration open
  and block writes; large tables need batched backfills run separately.
- **Indexes / constraints.** Adding indexes, NOT NULL, or foreign keys
  to populated columns may require table locks or rewrites. Online
  index syntax, two-step NOT NULL, or deferred FK validation may be
  warranted.
- **DB version + algorithm support.** Confirm the production MariaDB /
  MySQL version and whether the change qualifies for `ALGORITHM=INSTANT`
  or `INPLACE`. INSTANT ADD COLUMN (MariaDB 10.3+, MySQL 8.0.12+) makes
  nullable+default column adds metadata-only; without it the same
  migration can rewrite the table. Check both Wiki Ed Dashboard
  (`production` stage) and Peony (`peony` stage) — they're independent
  hosts and may run different MariaDB versions. `SELECT VERSION();` on
  each is the cheap check.
- **Table size.** Roughly how big is the affected table in production?
  Small tables (<100K rows) tolerate any algorithm; large or write-hot
  tables (e.g. `course_wiki_timeslices`, `revisions`,
  `course_user_wiki_timeslices`, `article_course_timeslices`) need a
  fast-path algorithm or out-of-band execution.
- **Deploy timing.** Capistrano runs migrations during deploy and the
  deploy blocks on them. For migrations that aren't fast-path,
  recommend running out-of-band first and shipping the code change in
  a follow-up deploy.

State a verdict — "safe to ship inside a normal deploy" or specifics
about what to do differently — before continuing.

### Diff walkthrough

Walk through the diff one logical group at a time. For each group of
related changes:

1. Show the diff (use `gh pr diff <number>` or read the changed files).
2. Summarize what the changes do — but **do not judge quality**. Present
   the facts and let the reviewer assess.
3. Flag areas that may warrant closer attention:
   - **Migrations** — covered above in Migration safety check; the diff
     walkthrough should still surface any code that depends on the new
     schema in ways that interact with the deploy ordering.
   - **Security-sensitive code** — authentication, authorization, user
     input handling, SQL queries, external API credentials
   - **External API changes** — calls to WikiMedia APIs, Toolforge
     services, or third-party endpoints
   - **Performance** — N+1 queries, large data operations, missing
     indexes
   - **Side effects** — changes to Sidekiq jobs, cron schedules, email
     sending, external service calls

After presenting each group, pause for the reviewer's questions or
comments before continuing.

---

## Phase 6: Testing

By this point, the Phase 3 baseline specs and Phase 4 exploratory
specs have already run. This phase covers additional testing beyond
that baseline.

**Run the PR's own specs.** If the PR includes spec files that
weren't already run in the Phase 3 baseline, run them now:
```bash
bundle exec rspec <pr_spec_files>
```

**Offer additional testing options:**
- **Full suite** — `bundle exec rspec` (takes a while). Recommended
  for PRs that touch shared code (helpers, presenters, base classes).
- **Manual testing** — for UI changes, offer to start the dev server
  and describe what to check.

Report all test results clearly. If there are failures, determine
whether they're PR-introduced or pre-existing (by comparing to
master) and report accordingly.

---

## Phase 7: Wrap up

This phase applies to both first-time reviews and re-reviews.

### Coverage confidence assessment

Review the **entire PR diff** (not just the delta, for re-reviews)
and produce a structured assessment of how thoroughly the changeset
is tested and where risk remains. This is for the reviewer's benefit,
not for posting.

**For each area of the PR**, classify into three buckets:

1. **Well-tested** — code paths exercised by the PR's own specs or
   the existing test suite. Note which specs cover which functionality.

2. **Exploratory-only** — covered by specs written during review but
   not by the PR's own specs. These paths will lose coverage if the
   exploratory specs aren't adopted by the author.

3. **Untested** — no spec coverage at all. For each untested area,
   assess:
   - **Bug risk**: How likely is this to hide a bug? Consider
     complexity, number of branches, interaction with external
     state (DB queries, API calls, JS library initialization),
     and whether the code was written to fix a prior bug.
   - **Failure visibility**: If this code is wrong, would it fail
     loudly (error, crash) or silently (wrong data, subtle UI
     issue)?
   - **Blast radius**: Does this affect all users, or only a
     specific flow (e.g., advanced search with a particular filter
     combination)?

Present this to the reviewer and ask whether any higher-risk untested
areas warrant writing additional specs or flagging to the author
before approving.

### Pre-merge checklist

Present a checklist covering each of these. Mark each as pass, fail,
or not applicable. Failed items aren't necessarily blocking — the
reviewer decides — but all must be explicitly assessed.

- [ ] **Build succeeds** — `yarn build` completes without errors
- [ ] **Linters pass** — RuboCop and ESLint clean on changed files
- [ ] **PR's own specs pass** — all spec files included in the PR
- [ ] **Existing specs pass** — no regressions in specs for affected
      areas (from Phase 3 baseline)
- [ ] **Exploratory specs pass** — if written during review
- [ ] **No high-risk untested areas** — or reviewer has accepted the
      risk (from coverage assessment above)
- [ ] **Review feedback addressed** — for re-reviews: all prior
      issues resolved or explicitly deferred

### Summary

Summarize the review status:
- Pre-merge checklist results (from above)
- Coverage confidence assessment highlights
- Any open concerns the reviewer noted during the process
- Whether the reviewer is ready to approve, request changes, or needs
  more information

If the reviewer wants to leave a review, help draft it (see below),
then submit via:
```bash
gh pr review <number> --approve --body "..."
gh pr review <number> --request-changes --body "..."
gh pr review <number> --comment --body "..."
```

After a `--request-changes` review, convert the PR to draft so it
leaves the review queue until the author pushes fixes:

```bash
gh pr ready <number> --undo
```

Do not do this for `--comment` or `--approve` reviews. When the
author marks the PR ready for review again, that's the signal to
re-review.

Clean up: delete any temporary exploratory spec files, then switch
back to the previous branch:
```bash
git checkout master
```

---

## Re-review workflow

When Phase 1 detects a prior review with new commits since, use this
workflow instead of Phases 2–5. Phase 7 (Wrap up) still applies
afterward.

### Step 1: Scope the delta

Identify what changed since the last review:
```bash
# Commits since the reviewed commit
gh api repos/WikiEducationFoundation/WikiEduDashboard/pulls/<number>/commits \
  --jq '[.[] | {sha: .sha[0:10], message: .commit.message | split("\n")[0], date: .commit.author.date}]'
```

Note which commits are new (after the prior review's `submitted_at`).
Fetch the diff scoped to just the new changes:
```bash
git diff <reviewed_commit_sha>..HEAD
```

Present the reviewer with: how many new commits, what they claim to
address (from commit messages), and the size of the delta.

### Step 2: Check prior feedback

Parse the prior review comments and PR comments into a list of
specific issues raised. For each issue:

1. Read the relevant file(s) in their current state.
2. Determine whether the issue is **resolved**, **partially
   addressed**, or **not addressed**.
3. If resolved, note briefly how (e.g., "method moved to private
   section in commit abc123").
4. If partially addressed or not addressed, note what remains.

Present findings as a table:

| Issue | Status | Notes |
|---|---|---|
| `joins` should be `left_joins` | Resolved | Fixed in abc1234 |
| Inline JS should be extracted | Partial | Extracted to file but inline blocks remain |
| ... | ... | ... |

Ask the reviewer if the assessments look right before continuing.

### Step 3: Review the delta for new issues

Walk through the new-commits diff (from Step 1) looking for issues
introduced by the fixes themselves. Common patterns:

- **Incomplete cleanup** — old code left behind after extraction
  (e.g., duplicated logic in two places)
- **Regression** — a fix that breaks something that previously worked
- **New code that wasn't in the original review** — functionality or
  files added alongside the fixes that warrant their own review

Apply the same review lens as Phase 5 (security, performance, side
effects, etc.) but scoped to the delta only. Don't re-review code
that was already covered in the original review and hasn't changed.

### Step 4: Rerun specs and assess coverage

Check out the PR branch (or update the existing checkout):
```bash
gh pr checkout <number> --branch review/<number>
git merge master --no-edit
```

If `package.json` changed in the new commits, run `yarn install`.
Always run `yarn build` and confirm it succeeds without errors.

**Run existing specs for affected areas** (same as Phase 3 baseline).
Map changed files to their corresponding spec files and run them.
Compare failures to master to distinguish PR-introduced regressions
from pre-existing issues.

**Rerun the PR's own specs.** If the PR includes spec files, run them:
```bash
bundle exec rspec <spec files from the PR>
```
Report pass/fail. Failures here may indicate regressions introduced
by the fix commits.

**Rerun exploratory specs.** If exploratory specs were written during
the original review, rerun them to see if previously-failing examples
now pass — these are a direct check on the claimed fixes. If some
still fail, those are unresolved issues; add them to the table from
Step 2. If the new commits introduced functionality not covered by
the existing specs, offer to extend them.

**Assess and fill test coverage gaps.** Check whether the new commits
added or changed logic that lacks spec coverage. In particular:
- New methods or branches added by fix commits
- Code paths that were only tested by the exploratory spec (which
  won't be committed) and not by the PR's own specs
- Any functionality where the PR's specs only test the happy path

If significant coverage gaps exist — whether from the original PR or
introduced by the fix commits — write specs to fill them, following
the same approach as Phase 4 (exploratory specs). These serve the
review: they verify the fixes work, expose regressions, and give
the reviewer confidence in the code. Specs that the author should
adopt can be shared in the follow-up comment.

If no exploratory specs exist from the original review and the PR
includes no spec files, this is a significant gap. Write specs that
cover the core functionality before proceeding — don't move on
without being able to verify the code works.

### Step 5: Draft follow-up comment

Compose a follow-up comment structured as:

1. **Acknowledgment** — which issues from the prior review were
   addressed (keep brief; the table is for internal use, not the
   comment).
2. **Remaining issues** — anything not yet resolved, with enough
   context for the author to act on.
3. **New issues** — anything found in the new commits.

Follow the same tone and attribution rules as "Posting review
comments" below. After drafting, show it to the reviewer for approval
before posting.

After posting, proceed to Phase 7 (Wrap up). Phase 6 (Testing)
is usually unnecessary since Step 4 already covers spec runs, but
offer it if the reviewer wants broader testing (e.g., full suite,
manual testing).

---

## Posting review comments

All review comments and PR feedback posted via this skill must follow
these rules:

**How to use feedback:** At the start of a review, include a note about
how we intend AI-driven review feedback to be used — not to be automatically
trusted or blindly acted upon, but good to read, understand and use or
ignore based on the developer's own judgment.

**Approval required:** Never post a review or comment without first
showing the full draft to the reviewer and receiving explicit approval.
Always wait for confirmation before running `gh pr review` or
`gh pr comment`.

**Tone:** Impersonal and direct. No first-person ("I found..."). No
chatbot pleasantries ("Nice work!", "Great PR!"). Use passive voice
or refer to "the code", "the session", "Claude Code" where needed.
Frame findings as observations that warrant verification, not as
authoritative conclusions — AI analysis is provisional and may be
wrong.

**Attribution:** Every posted comment must end with an italicized
attribution line that honestly characterizes the human involvement.
Include: how much wall-clock time the reviewer spent, roughly how
many interactions they had with Claude Code, what they actually
reviewed vs. what they approved without deep verification, and — if
local verification happened — what specifically was verified ("ran X
locally", "reproduced Y via a new spec", "checked production
state"). The goal is to let the PR author calibrate how much weight
to give the feedback; named verifications calibrate more sharply
than time and interaction counts alone. Examples:

*Drafted in a Claude Code session (~30 min, ~15 interactions).
Sage directed the triage and code review phases, verified the
`joins` bug independently, and reviewed the full comment before
posting. Other findings were spot-checked but not all individually
verified.*

*Drafted in a Claude Code session (~5 min, 3 interactions). Sage
approved posting after a quick read-through but did not independently
verify the findings.*

If the comment includes AI-generated code (such as an exploratory
spec), say so explicitly and note whether the reviewer ran or
reviewed that code.

**Link:** After posting any review or comment, fetch and display the
URL so the reviewer can click through:
```bash
gh api repos/WikiEducationFoundation/WikiEduDashboard/pulls/<number>/reviews --jq '.[-1].html_url'
```
