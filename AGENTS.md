# WikiEduDashboard agent instructions

The single canonical source of repository instructions is
`.claude/CLAUDE.md`. Read that file in full before taking any action in this
repository, and follow it as though its contents appeared here.

The reusable workflows referenced there are stored under `.claude/skills/` and
`.claude/commands/`. When a task matches one of those workflows, read its
instructions in full before gathering data or acting, even if the current
agent does not automatically discover workflows from those directories.

Do not copy the canonical instructions or workflow contents into this file.
This file exists only so agents that support the `AGENTS.md` convention load
the same guidance as Claude Code.
