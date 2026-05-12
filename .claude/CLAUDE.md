# WikiEduDashboard — Claude Code Instructions

## Running tests and linting

```bash
bundle exec rspec spec/path/to/spec.rb   # single spec file
bundle exec rspec                         # full Ruby suite
bin/full-suite                            # full suite + archive coverage
bundle exec rubocop                       # lint Ruby
yarn test                                 # JavaScript suite
yarn lint-non-build                       # ESLint on test/ and root JS files
```

When asked to run the full test suite and save coverage, use `bin/full-suite`.
It runs `bundle exec rspec`, then renames `coverage/` to
`coverage.all.YYYY-MM-DD/` (with a numeric suffix if that name already exists).

RuboCop and ESLint are enforced. Fix offenses before considering a task done.
Key project limits (differ from RuboCop defaults):
- Line length: 100 characters
- Method length: 16 lines
- ABC size: 23
- Class length: 130 lines

## Project structure

- `app/services/` — plain Ruby service objects, one public responsibility each
- `lib/` — utilities, API wrappers, and domain logic
- `lib/utils/` — small utility classes (e.g. WikiUrlParser)
- `spec/services/` — service specs; `spec/lib/` — lib specs
- `fixtures/vcr_cassettes/` — recorded HTTP interactions for specs (not committed)

## Service class conventions

- **Naming**: verb + noun, CamelCase, no "Service" suffix — e.g. `GetRevisionPlaintext`, `ExtractClaimsAndSources`
- **File**: `app/services/snake_case_name.rb`
- Initialize with all required inputs; call the main method at the end of `initialize`
- Expose results via `attr_reader`; keep everything else `private`
- Use `require_dependency "#{Rails.root}/lib/..."` for `lib/` files that may not be autoloaded

Example skeleton:
```ruby
# frozen_string_literal: true

class DoSomethingUseful
  attr_reader :result

  def initialize(input)
    @input = input
    @result = []
    perform
  end

  private

  def perform
    # ...
  end
end
```

## WikiApi usage

Use `WikiApi.new(wiki)` for MediaWiki API calls. The standard public methods
(`query`, `get_page_content`, etc.) are preferred. For actions not covered by
public methods, follow the pattern used in `GetRevisionPlaintext`:

```ruby
@wiki_api.send(:api_client).send('action', 'parse', params)
```

## Stylesheets

Stylesheets are in `app/assets/stylesheets/` and use Stylus. Changes have no
effect until the assets are recompiled:

```bash
yarn build   # one-off compile (exits when done; use before running tests)
yarn start   # continuous watcher (recompiles on save; normally running in dev)
```

Run `yarn build` yourself (don't ask the user to do it) before running feature
specs that depend on CSS changes.
New module files in `app/assets/stylesheets/modules/` are auto-imported via the
`@import "modules/*"` glob in `main.styl` — no manual import needed.

## Feature specs

Run feature specs with `bin/feature-spec`. Once the user has asked to "show me"
in a session, run all subsequent feature specs headed (`HEADED=1`) for the rest
of that session. Only add `SLOW=` when the user explicitly requests slow mode.

Never commit without being asked, even after a spec run succeeds.

## Specs

- Always `require 'rails_helper'`
- Use VCR for specs that hit external APIs:
  ```ruby
  VCR.use_cassette 'subdirectory/cassette_name' do
    # ...
  end
  ```
  Cassette files live in `fixtures/vcr_cassettes/` and are **not committed to git**
- Do not define constants at the top level of a spec file — use local variables
  inside the `describe` block instead, to avoid re-initialization errors
- Prefer one focused `it` block per behavior; avoid bundling unrelated assertions

## Production infrastructure

Two independent production deployments share this codebase:

| | Wiki Ed Dashboard | Programs & Events Dashboard |
|---|---|---|
| Cap stage | `production` | `peony` |
| Branch | `production` | `wmflabs` |
| Web server | `dashboard.wikiedu.org` | `peony-web` (WMCloud) |
| DB server | same host | `peony-database` (WMCloud) |

Wiki Ed runs on a single server. The P&E Dashboard is distributed across
WMCloud VPS (`globaleducation` project):
- **Web**: `peony-web` — app + `sidekiq-default`, `sidekiq-daily` (deployed via Capistrano)
- **Sidekiq**: `peony-sidekiq` (long, constant), `peony-sidekiq-medium`, `peony-sidekiq-3` (short) — **not** deployed via Capistrano; updated manually with `git pull` + `bundle install`
- **Database**: `peony-database` — MariaDB, data on Cinder volume at `/srv`
- **Redis**: `p-and-e-dashboard-redis` — shared across all Sidekiq processes

The Dashboard depends on several Wikimedia Toolforge services, notably the
**replica revision tools** (`replica-revision-tools.wmcloud.org`, source:
`WikiEducationFoundation/WikiEduDashboardTools`) which provides PHP endpoints
for querying Wikimedia replica databases. See `docs/admin_guide.md` for the
full list of integrated Toolforge tools and third-party APIs.

## AI attribution on external communication

Anything Claude publishes that another person reads as if a human wrote it
must be explicitly marked as AI-generated. It must never be ambiguous or
unstated when AI does things in this repo.

- **PR / issue / review comments** posted via `gh pr comment`,
  `gh issue comment`, `gh pr review`, etc.: end the body with a blank line
  and `(Comment written by Claude Code.)`.
- **PR descriptions** created via `gh pr create`: end the body with
  `(PR description written by Claude Code.)` (the `/prepare-pr` skill
  already handles this — keep using it).
- **Commit messages**: the `/commit` skill already adds
  `(Commit message written by Claude Code.)` and the `Co-Authored-By:`
  trailer. Keep using it.
- **Anything else published to humans** (Slack drafts, email drafts,
  public docs, etc.): add an equivalent trailer. When in doubt, add the
  marker.

## PR review

Always use the `/review-pr` skill when reviewing or revisiting a pull request.
Load it immediately — do not gather PR data manually first.

## Commit messages

Always use the `/commit` skill when creating commits. It handles staging,
message format, and session accounting.

While working, note anything that would otherwise be lost by commit time:
pre-existing code the user brought in, abandoned approaches, or any context
about the session character that isn't visible in the tool call history.
