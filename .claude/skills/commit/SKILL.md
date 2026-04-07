---
name: commit
description: Stage and commit changes with a well-formed commit message following the WikiEduDashboard format. Use this skill when asked to commit, make a commit, or create a commit.
---

# Commit

Create a git commit with a message that follows the project's format.

## Phase 1: Understand what's being committed

1. `git status` — identify staged and unstaged files
2. `git diff --staged` — read every staged change in detail
3. `git diff` — note any unstaged changes (do not commit these unless asked)
4. Review the conversation history — what was the user trying to accomplish, and why?

## Phase 2: Draft the commit message

Follow the project format exactly:

```
<Subject line: imperative mood, ≤72 chars>

## Changes

<What was built or changed and why, organized by file or component.
Include any non-obvious design decisions or tradeoffs.>

## Process

<How Claude Code was used: what the user asked for, what approach was taken,
any errors or corrections along the way. Be candid and specific — if Claude
got something wrong and needed correction, say so. If the solution was
straightforward, say that too.>

(Commit message written by Claude Code.)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

### Subject line guidelines

- Imperative mood: "Fix flaky spec" not "Fixed" or "Fixes"
- ≤72 characters
- No trailing period
- Specific enough to understand without reading the body

### Changes section guidelines

- Organize by file or logical component
- Explain *why*, not just *what* — the diff already shows what changed
- Call out non-obvious decisions or tradeoffs
- Keep it factual; don't pad

### Process section guidelines

Describe the actual back-and-forth, then include a session summary paragraph
covering the following. Be specific with numbers where you can; estimate and
note the uncertainty where you can't.

**Session provenance** — Did this session start from scratch, or were the
changes already partially or fully written before the session began? If the
user brought in pre-existing code or commits, say so and characterize how much
of the work predates this conversation.

**Prompts and human input** — How many messages did the user send? Roughly how
much text did they write in total (a few words, a sentence or two per message,
paragraph-length)? Was the direction terse or detailed?

**Session length and character** — Was this a short focused exchange (a handful
of turns) or an extended back-and-forth (many turns, multiple approaches tried)?
Did the work require iteration and correction, or was it resolved quickly?

**Tests run** — How many test runs happened over the course of the session, and
what was the outcome trajectory (e.g. "two failures before a clean pass", "green
on the first run")?

**Tokens** — If token usage is visible in the Claude Code UI, report it.
Otherwise omit this entirely.

This section exists so future readers can calibrate how much human direction and
iteration went into the work. Make it genuinely informative, not boilerplate.

## Phase 3: Commit

Stage files if needed, then commit using a HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
Subject line here

## Changes

...

## Process

...

(Commit message written by Claude Code.)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
EOF
)"
```

After committing, confirm success with `git log -1 --format="%h %s"`.
