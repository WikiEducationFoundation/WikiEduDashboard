# WikiEduDashboard — Claude Code Instructions

## Running tests and linting

```bash
bundle exec rspec spec/path/to/spec.rb   # single spec file
bundle exec rspec                         # full Ruby suite
bundle exec rubocop                       # lint Ruby
yarn test                                 # JavaScript suite
```

RuboCop is enforced. Fix offenses before considering a task done.
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

## Commit messages

Always use the `/commit` skill when creating commits. It handles staging,
message format, and session accounting.

While working, note anything that would otherwise be lost by commit time:
pre-existing code the user brought in, abandoned approaches, or any context
about the session character that isn't visible in the tool call history.
