# WikiEduDashboard — Claude Code Instructions

## Running tests and linting

```bash
bundle exec rspec spec/path/to/spec.rb   # single spec file
bundle exec rspec                         # full Ruby suite
bundle exec rubocop                       # lint Ruby
yarn test                                 # JavaScript suite
```

RuboCop is enforced. Run it on every file you touch before committing, and fix
all offenses. Do not rely on autocorrect alone — it sometimes produces ugly
line-breaks; fix those manually (e.g. extract a local variable to shorten the line).
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

Write commit messages in the following format when AI assistance was involved.
The subject line should be a concise imperative summary. The body has two sections:

```
<Subject line: imperative, ≤72 chars>

## Changes

<What was built or changed and why, organized by file or component.
Include any non-obvious design decisions or tradeoffs.>

## Process

<How Claude Code was used, what prompts or iterations were involved,
any errors or misunderstandings that came up and how they were resolved.
Be candid — if Claude got something wrong and needed correction, say so.>

(Commit message written by Claude Code.)

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>
```

The "Process" section is important: it gives future readers context about
which parts of the implementation were human-directed and which were
AI-generated, and it records the kind of back-and-forth that doesn't
otherwise appear in the diff.
