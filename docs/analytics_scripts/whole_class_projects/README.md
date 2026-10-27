# Whole-class group projects research

Research plan: [PLAN.md](PLAN.md). This file is the runbook.

## Phase 0: sanitizing the production dump

The raw dump must never pass through an AI agent. The operator runs every step
below in their own terminal; the agent gets access only to the sanitized
database, and only after the audit passes.

Database layout:

| Database | Contents | Who can read it |
|---|---|---|
| `wcp_raw` | the raw production dump | `wcp_sanitizer` only |
| `wcp_sanitized` | allowlisted, pseudonymized, scrubbed copy | `wcp_sanitizer`; `wiki` (read-only) after the audit passes |
| `wcp_analysis` | derived tables from later phases | `wiki` |

The agent uses the `wiki` MySQL user, which has no grants on `wcp_raw`. Keep the
`wcp_sanitizer` password out of your shell profile so the agent's shells never
see it.

### 1. Create databases and the operator user

```bash
sudo mysql <<'SQL'
CREATE DATABASE wcp_raw CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE wcp_sanitized CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE wcp_analysis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'wcp_sanitizer'@'localhost' IDENTIFIED BY 'choose-a-password';
GRANT ALL PRIVILEGES ON wcp_raw.* TO 'wcp_sanitizer'@'localhost';
GRANT ALL PRIVILEGES ON wcp_sanitized.* TO 'wcp_sanitizer'@'localhost';
SQL
```

### 2. Load the dump

Keep the dump outside the repo, in `~/whole_class_projects/`. From the repo
root, in a terminal session of your own:

```bash
read -rs WCP_DB_PASSWORD && export WCP_DB_PASSWORD
gunzip -c ~/whole_class_projects/dashboard-dump-2026-09-27-20:00:01.sql.gz \
  | mysql --no-defaults -u wcp_sanitizer -p"$WCP_DB_PASSWORD" -h 127.0.0.1 wcp_raw
```

If the load fails with an access-denied error naming another database, the dump
contains `USE`/`CREATE DATABASE` statements; tell the agent the error text (it
contains no row data).

### 3. Sanitize

```bash
bundle exec ruby docs/analytics_scripts/whole_class_projects/sanitize.rb
```

Prints row counts, dropped column names and replacement counts only.
Re-running needs `WCP_REBUILD=1`.

### 4. Audit

```bash
bundle exec ruby docs/analytics_scripts/whole_class_projects/audit_sanitized.rb
```

Its output is counts and schema names only and is safe to paste to the agent.
It fails only if private-looking columns (real names, emails, tokens) are still
present. Real names and emails found anywhere in text are reported as warnings;
they don't need to be removed. To see
what matched, run it with `--show` — that output contains raw values and must
not be pasted to the agent.

### 5. Grant the agent access

Only after the audit prints `RESULT: PASS`:

```bash
sudo mysql <<'SQL'
GRANT SELECT ON wcp_sanitized.* TO 'wiki'@'localhost';
GRANT ALL PRIVILEGES ON wcp_analysis.* TO 'wiki'@'localhost';
SQL
```

### 6. Retire the raw data

Keep `wcp_raw` and the dump file until Phase 1 confirms the allowlist has every
column the analysis needs (a missing column means re-running steps 3–4). Then:

```bash
sudo mysql -e 'DROP DATABASE wcp_raw'
rm ~/whole_class_projects/dashboard-dump-*.sql.gz
```

## Known limits of the scrubbing

- Instructor, volunteer and staff surnames that are ordinary words ("Young",
  "Rose") are replaced only after an honorific ("Dr. Young"), not bare.
- Real names that are a single dictionary word are not replaced.
- Usernames are kept everywhere, so a username that is someone's real name
  still appears (in `users.username`, userspace titles, sandbox URLs and any
  free-text `User:` link).
- Names of people who were never enrolled in the course (and are not staff) are
  caught only by the audit, not the scrubber.

(Runbook written by Claude Code.)
