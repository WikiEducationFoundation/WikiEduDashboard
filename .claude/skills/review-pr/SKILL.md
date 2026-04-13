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
Then move to Phase 2.

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

If there are local uncommitted changes, warn before proceeding.

If the PR adds or changes JS dependencies (`package.json` changed),
run `yarn install` before proceeding. If any feature specs or headed
demos will be needed, also run `yarn build`.

---

## Phase 4: Exploratory specs and demo

For PRs with user-facing changes, offer to write exploratory feature
specs that exercise the new functionality. This serves two purposes:
verifying the feature works and giving the reviewer a visual demo.

1. Read the changed views, controllers, and presenters to understand
   what the feature does.
2. Write a temporary spec file (`spec/features/<descriptive>_spec.rb`)
   with focused examples covering the key user flows and edge cases.
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

Skip this phase for PRs that are purely backend, configuration, or
refactoring with no user-visible changes.

---

## Phase 5: Code review

Run linters on the checked-out branch:
```bash
# Ruby files changed in the PR
bundle exec rubocop <changed .rb files>
# JS/JSX files changed in the PR
yarn eslint <changed .js/.jsx files>
```

Walk through the diff one logical group at a time. For each group of
related changes:

1. Show the diff (use `gh pr diff <number>` or read the changed files).
2. Summarize what the changes do — but **do not judge quality**. Present
   the facts and let the reviewer assess.
3. Flag areas that may warrant closer attention:
   - **Migrations** — schema changes, data migrations, irreversibility
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

Ask the reviewer what level of testing they want:

- **Run affected specs** — identify and run spec files that correspond
  to the changed files:
  ```bash
  bundle exec rspec <spec_files>
  ```

- **Run full suite** — `bundle exec rspec` (takes a while).

- **Manual testing** — for UI changes, offer to start the dev server
  (`yarn start` + `rails s`) and describe what to look at.

- **Skip** — reviewer is satisfied from the code review alone.

Report test results clearly. If there are failures, show them and ask
how the reviewer wants to proceed.

---

## Phase 7: Wrap up

Summarize the review status:
- What was checked (triage items, code areas, tests run)
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

Clean up: delete any temporary exploratory spec files, then switch
back to the previous branch:
```bash
git checkout master
```

---

## Posting review comments

All review comments and PR feedback posted via this skill must follow
these rules:

**Tone:** Impersonal and direct. No first-person ("I found..."). No
chatbot pleasantries ("Nice work!", "Great PR!"). Use passive voice
or refer to "the code", "the session", "Claude Code" where needed.
Frame findings as observations that warrant verification, not as
authoritative conclusions — AI analysis is provisional and may be
wrong.

**Attribution:** Every posted comment must end with an italicized
attribution line that honestly characterizes the human involvement.
Include: how much wall-clock time the reviewer spent, roughly how
many interactions they had with Claude Code, and what they actually
reviewed vs. what they approved without deep verification. The goal
is to let the PR author calibrate how much weight to give the
feedback. Examples:

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
