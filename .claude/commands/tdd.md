# TDD Mode

You are working in TDD mode. Follow these guidelines for the rest of this session.

## RED / GREEN / REFACTOR cycle

Work in explicit phases and do not skip ahead:

**RED** — Write a failing test first. Do NOT write any implementation yet. Run the
spec to confirm it fails for the right reason before proceeding.

**GREEN** — Write the minimum implementation to make the test pass. Do not add
anything not required by the current tests.

**REFACTOR** — Improve code quality while keeping tests green. Check RuboCop,
method length, and clarity.

If the user's instruction is ambiguous about which phase to be in, ask.

## Reporting test results

- When a spec run has failures, report the output immediately — do not spend time
  analyzing before showing results. The user can often diagnose quickly from the
  raw output and will ask you to investigate further if needed.
- When all specs pass, say so concisely and wait for next instructions.

## Running specs

Prefer targeted runs over the full suite while iterating:

```bash
bundle exec rspec spec/path/to/spec.rb                  # single file
bundle exec rspec spec/path/to/spec.rb:42               # single example by line
bundle exec rspec spec/path/to/spec.rb -e 'description' # single example by name
bundle exec rspec                                        # full suite (use to confirm before committing)
```

Add `--format documentation` when exploring behavior or diagnosing failures.

## Isolating examples

When a specific case needs repeated targeted runs, add a named `describe` block
for it rather than relying on `-e` string matching. This makes it easy for both
you and the user to run it precisely:

```ruby
describe 'MyClass some specific scenario' do
  let(:result) { ... }
  it 'does the expected thing' do
    expect(result).to eq(...)
  end
end
```

## Diagnostic tests

Use `xdescribe`/`xit` to park exploratory or diagnostic tests without deleting
them — they are skipped by the runner but preserved for later:

```ruby
xdescribe 'diagnostic' do
  it 'prints output for inspection' do
    # puts / p statements for exploratory output
  end
end
```

Remove or keep diagnostic blocks based on the user's preference.

## Linting

Run RuboCop on every file you touch before committing — including spec files:

```bash
bundle exec rubocop path/to/file.rb path/to/spec.rb
```

Fix all offenses before committing. Do not rely on autocorrect alone.

## Exploration

Use RSpec as the primary exploration tool. Avoid one-off bash or python commands
for investigation — write a spec instead. This keeps findings reproducible and
useful to human developers working on the same code later.
