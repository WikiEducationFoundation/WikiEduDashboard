---
name: feature-spec
description: Write browser-based Capybara feature specs for WikiEduDashboard controllers and views. Use this skill when asked to improve test coverage, write feature specs, add browser tests, or cover a controller with specs.
---

# Feature Spec Writer

Write concise, high-level Capybara feature specs that exercise controller code the way a real user would — visiting pages, filling forms, clicking buttons — rather than testing implementation details.

## Goal

Cover every executable line in the target file, using the fewest, most readable specs possible. Start by exploring, write the spec, run it, check coverage, and iterate until coverage is complete.

## Phase 1: Explore

Before writing anything, read:

1. **The target file** — understand every action, before_action, private method, and branch
2. **The routes** (`config/routes.rb`) — find the URL paths
3. **The views** — know what content will be on the page (text to assert, form fields to fill)
4. **Error handling** — check `lib/errors/rescue_errors.rb` for how exceptions render (what text appears for unauthorized, not-signed-in, etc.)
5. **Relevant factories** — `spec/factories/` to know what's available and what associations are required
6. **A few existing feature specs** in `spec/features/` for patterns

Note every branch in `check_permission` or similar guards — each branch needs its own scenario.

## Phase 2: Write the spec

File location: `spec/features/<controller_name_snake>_spec.rb`

### Template

```ruby
# frozen_string_literal: true

require 'rails_helper'

describe 'Brief description of feature', type: :feature, js: true do
  let(:course) { create(:course) }
  let(:user)   { create(:user) }
  # ... other shared setup

  describe 'as [role/scenario]' do
    before { login_as(user) }

    it 'does the main thing' do
      visit '/path/to/page'
      expect(page).to have_content 'Expected text'
      # interact with the page...
      click_button 'Submit'
      expect(page).to have_content 'Success message'
    end
  end

  # one describe block per distinct permission/scenario
end
```

### Key conventions

- `require 'rails_helper'` — always
- `type: :feature, js: true` — always put both on the top-level `describe`. Every feature spec runs through Selenium so "show me" works on any spec.
- Auth: `login_as(user)` in a `before` block (Warden test helpers, already configured)
- Factories: `create(:factory_name, association: other_record, field: value)`
- Instructors: `create(:courses_user, user: instructor, course: course, role: CoursesUsers::Roles::INSTRUCTOR_ROLE)`
- Admins: `create(:admin)`
- No constants at top level of describe block — use `let`

### What to cover

For a typical permission-gated controller, you need one scenario per permission branch:

| Scenario | What to check |
|---|---|
| Owner/authorized user — happy path | Form renders AND form submits successfully |
| Admin | Page renders |
| Instructor | Page renders |
| Unauthorized (signed in, wrong user) | Error text visible (e.g., "not authorized") |
| Unauthenticated | Sign-in prompt visible (e.g., "Please sign in.") |

Collapse the "can view" cases for admin and instructor into minimal single `it` blocks — just visit the page and assert one piece of content. Save the fuller interaction test for the main authorized-user scenario.

### Error page text

- `NotSignedInError` → renders `errors/unauthorized` → shows `"Please sign in."` in flash
- `ActionController::InvalidAuthenticityToken` → `rescue_invalid_token` → renders plain text `"not authorized"` (check `lib/errors/rescue_errors.rb` and `config/locales/en.yml` for the exact phrase)

## Phase 3: Run and iterate

Always use `bin/feature-spec` to run specs — it prints rspec's normal colored output, then appends a colored coverage summary for the target file:

```bash
bin/feature-spec spec/features/<spec_file>_spec.rb [app/controllers/<target>_controller.rb]
```

The target file argument is optional; if omitted it's guessed from the spec name. After every run, always report the key results as a text message (outside the collapsed tool output):
- Pass/fail count and time (from the rspec summary line)
- Coverage percentage and covered/total lines
- Uncovered line numbers if any

Example: `5 examples, 0 failures (3.4s) — 100% coverage (22/22 lines)`

The coverage summary colors in the script output:
- **Green** — 100% covered
- **Yellow** — ≥80% covered
- **Red** — below 80%, with a list of uncovered line numbers

If the user says **"show me"**, prefix with `HEADED=1` so Chrome opens visibly:

```bash
HEADED=1 bin/feature-spec spec/features/<spec_file>_spec.rb
```

If the user says **"show me slowly"**, add `SLOW=0.3` to pause after each click, fill, check, and select:

```bash
HEADED=1 SLOW=0.3 bin/feature-spec spec/features/<spec_file>_spec.rb
```

The `SLOW` value is the pause in seconds — `SLOW=0.1` for a quick flash, `SLOW=1` for a full second, etc.

A line count of `None` in the raw resultset means non-executable (comments, blank lines, `end`). Only `0` means missed — those are what appear in the "Uncovered lines" list.

**Iterate** — for each uncovered line:
- Identify which branch or condition it's in
- Add a new scenario (or extend an existing one) that exercises it
- Re-run and re-check

## Phase 4: Rubocop

```bash
bundle exec rubocop spec/features/<spec_file>_spec.rb
```

Fix any offenses before finishing.

## Tips

- **Minimal factory setup** — only set associations that are actually used by the controller or view. Don't add `article:` if the code handles nil articles gracefully.
- **Assert content, not implementation** — check for flash messages, page text, and form fields, not internal state (except when verifying a save, like checking `record.reload.attribute`).
- **One submit test is enough** — if the form submit path is covered once, don't repeat it for admin/instructor scenarios.
- **Check the view for assert text** — the exact strings on the page come from the view template or i18n keys.
- **`details:` hashes** — when a model uses `serialize :details, type: Hash`, pass the hash directly in the factory: `create(:alert, details: { key: 'value' })`.
