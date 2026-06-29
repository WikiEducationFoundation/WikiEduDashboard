# frozen_string_literal: true

Capybara.asset_host = 'http://localhost:3000'

# Allow `click_button` / `click_link` / etc. to match an element by its
# `aria-label` in addition to the default text/value/title/id locators.
# Aligns Capybara's element finders with accessibility-name semantics so
# icon-only controls with `aria-label` are reachable by spec text the same
# way they're reachable by screen-reader users.
Capybara.enable_aria_label = true
