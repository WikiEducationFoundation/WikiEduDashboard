# Dependency security audit — High-severity Dependabot alerts

**Date:** 2026-06-29
**Branch:** `dependency-security-updates`
**Scope:** Open **High**-severity Dependabot alerts on
`WikiEducationFoundation/WikiEduDashboard`.

This document tracks the High-severity alerts that could **not** be cleared with
a safe, drop-in version bump and were deliberately deferred. Each entry records
why it is more involved than a patch bump, a recommended fix, and a rough risk
assessment. The straightforward upgrades were committed individually on this
branch (see [Fixed on this branch](#fixed-on-this-branch)).

Versions below reflect what was installed in `Gemfile.lock` / `yarn.lock` at the
time of triage (local HEAD matched `origin/master`, i.e. what Dependabot scans).

---

## Deferred — needs more than a safe bump

### 1. tinymce (no fixed release exists) — ✅ RESOLVED 2026-06-29 (replaced)

- **Alerts (all high, XSS):** GHSA-vg35-5wq7-3x7w (media plugin
  `data-mce-object` injection), GHSA-v98h-vmpc-fpqv (`mce:protected` comments),
  GHSA-q742-qvgc-gc2f (`data-mce-` prefixed `src`/`href`/`style`).
- **Was:** `tinymce ^5.2.2` + `@tinymce/tinymce-react ^3.12.6`, used for
  TextAreaInput's wysiwyg mode (timeline blocks, ticket replies).
- **What the deeper look found:** the advisories' affected ranges are `< 5.11.1`
  (no fix — that release never shipped), `>= 6.0.0, < 7.9.3` (fixed 7.9.3), and
  `>= 8.0.0, < 8.5.1` (fixed 8.5.1). So TinyMCE 6 does **not** fix it; the real
  floor is 7.9.3 / 8.5.1 — and TinyMCE 7+ relicensed to GPL-2.0-or-later (8.3+ to
  a custom license). That's a heavy, copyleft editor for what is only light
  formatting here, with one real requirement: occasional direct HTML editing of
  block content.
- **Fix shipped (branch `tinymce-to-tiptap`):** replaced TinyMCE with a TipTap
  (ProseMirror) editor — MIT-licensed, lighter, no skins build step. The HTML-
  editing need is met by a source-view toggle. Dropping TinyMCE removes the
  vulnerable package from the tree entirely. Standard authored content
  round-trips faithfully; legacy blocks with out-of-schema markup normalize on
  save (an accepted tradeoff). Verified by build, Jest, and two real-browser
  feature specs (timeline block edit+save, ticket reply incl. an axe a11y check).

### 2. linkify-it (needs markdown-it major upgrade) — ✅ RESOLVED 2026-06-29

- **Alert:** GHSA-22p9-wv53-3rq4 (high) — quadratic ReDoS in `LinkifyIt#match`.
- **Range / patch:** `<= 5.0.0`, patched `5.0.1`.
- **Was:** `linkify-it 3.0.3`, pulled **only** by `markdown-it@12.3.2`. linkify-it
  is bundled by markdown-it, so the only path to the patched 5.x line was a
  markdown-it major upgrade.
- **Fix shipped:** Bumped `markdown-it` ^12.3.2 → **^14.2.0** and
  `markdown-it-footnote` ^3.0.2 → **^4.0.0** (branch
  `linkify-it-markdown-it-upgrade`). This pulled `linkify-it` 5.0.1 and also
  cleared the separate medium markdown-it alert #389 (patched 14.2.0). Our usage
  is centralized in `app/assets/javascripts/utils/markdown_it.js` (a thin wrapper
  using only `html`/`linkify`/`.use(footnotes)`/`.render()` and a stable
  token-API renderer override), so no app code changed. Verified: the existing
  markdown specs, the full Jest suite (406 tests), the production build, and an
  ad-hoc footnote+linkify render all pass.

### 3. js-cookie (needs react-cookie-consent upgrade) — ✅ RESOLVED 2026-06-29

- **Alert:** GHSA-qjx8-664m-686j (high) — per-instance prototype hijack in
  `assign()` enabling cookie-attribute injection.
- **Range / patch:** `<= 3.0.5`, patched `3.0.7`.
- **Was:** `js-cookie 2.2.1`, pulled by `react-cookie-consent@8.0.1`. **Runtime**
  — the cookie-consent banner, and the re-exported `Cookies` used by
  notes_panel / notes_modal_trigger / news_nav_icon.
- **Fix shipped (branch `js-cookie-upgrade`):** bumped `react-cookie-consent`
  ^8.0.1 → ^10.0.1, the first release on js-cookie 3.x (requires React ≥18, which
  we satisfy). That carries js-cookie 2.2.1 → 3.0.8 (patched). v10 still
  re-exports `Cookies` and `CookieConsent` (default), and js-cookie's
  `set(name, value, { expires })` / `get(name)` API is unchanged 2 → 3, so no app
  source changed.
- **Verification:** js-cookie resolves to a single 3.0.8; production build
  compiles; Jest suite passes; and a throwaway Capybara feature spec rendered the
  banner and confirmed "I understand" dismisses it in a real browser (the banner
  is disabled in the test env, so the spec temporarily enabled it; that edit was
  reverted).

### 4. tar (only patched on the 7.x line; cacache pins 6.x) — ✅ RESOLVED 2026-06-29

- **Alerts (all high):** GHSA-9ppj-qmqm-q256, GHSA-qffp-2rhf-9h96,
  GHSA-83g3-92jg-28cx, GHSA-34x7-hfp2-rc4v, GHSA-r6q2-hw4h-h46w,
  GHSA-8qq5-rm4j-mr97 — symlink/hardlink path traversal and extraction race
  conditions in node-tar.
- **Was:** `tar 6.2.1`, held by the resolution `"tar": "^6.2.1"`; required by
  `cacache@16.1.1` (`tar ^6.1.11`) and `node-gyp@9.0.0`. That whole subtree
  exists only to build `fsevents` (a macOS-only native file-watcher) at install
  time — not in the server runtime or browser bundle, and nothing extracts
  untrusted archives, so real-world exposure was minimal.
- **Fix shipped (branch `linkify-it-markdown-it-upgrade`):** tar is patched only
  on the 7.x line, and `cacache@16` uses the tar 6 API, so rather than forcing
  tar 7 under it the whole toolchain was bumped: resolution `node-gyp` →
  `^11.5.0` (lenient engine `^18.17.0 || >=20.5.0`), which cascades
  `make-fetch-happen` 10 → 14 → `cacache` 16 → 19, all on `tar ^7.4.3`; and the
  `tar` resolution `^6.2.1` → `^7.5.4`. Result: a single `tar 7.5.19` in the
  lockfile (no 6.x copy), which also clears the related medium tar alert.
  Verified: clean `yarn install`, full Jest suite (406 tests), and production
  webpack build. The macOS native-build path can't be exercised on CI but is
  build-time-only by nature.

### 5. serialize-javascript — ✅ RESOLVED 2026-06-29

- **Alert:** GHSA-5c6j-r48x-rmvq (high) — RCE via `RegExp.flags` /
  `Date.prototype.toISOString()`.
- **Range / patch:** `<= 7.0.2` (high) and `< 7.0.5` (medium); patched `7.0.3` /
  `7.0.5`.
- **Was:** `serialize-javascript 6.0.0`, pulled by `css-minimizer-webpack-plugin@4.0.0`
  (`serialize-javascript ^6.0.0`). **Build-time only** — serializes the minifier
  cache key, not attacker input.
- **Correction to the original plan:** "bump css-minimizer-webpack-plugin to a
  release that uses serialize-javascript 7.x" turned out to be unviable — *every*
  css-minimizer-webpack-plugin version (through the current 8.x) pins
  serialize-javascript at `^6.0.x`, and the high advisory covers everything
  `<= 7.0.2`, so 6.0.x is vulnerable too.
- **Fix shipped:** forced serialize-javascript to 7.x with a resolution
  (`serialize-javascript@^6.0.0` → `^7.0.5`, resolves to 7.0.6).
  css-minimizer-webpack-plugin@4 is its only consumer (terser-webpack-plugin no
  longer depends on it) and its `serialize()` usage is compatible across 6 → 7.
  Verified by the production webpack build (CSS minified and emitted) plus the
  Jest suite.

### 6. flatted (legacy 2.x line) — shares a fix with tmp — ✅ RESOLVED 2026-06-29

- **Alerts (high):** GHSA-rf6f-7fwh-wjgh (`<= 3.4.1`, prototype pollution),
  GHSA-25h7-pfq9-p65f (`< 3.4.0`, unbounded-recursion DoS).
- **Was:** The 3.x flatted line was already patched (`3.4.2`); only the legacy
  `flatted 2.0.2` was vulnerable, via `flat-cache@2.0.1` ← `file-entry-cache@5.0.1`
  ← `eslint@6.8.0` ← `rewire@5.0.0`. **Dev-only.**
- **Fix shipped:** the `rewire` bump below removed the `eslint@6.8.0` subtree;
  `flatted@2.0.2` is gone and only the patched `flatted@3.4.2` remains.

### 7. tmp — shares a fix with flatted (rewire) — ✅ RESOLVED 2026-06-29

- **Alert:** GHSA-ph9p-34f9-6g65 (high) — path traversal via unsanitized
  prefix/postfix enabling directory escape.
- **Was:** `tmp 0.0.33` ← `external-editor@3.1.0` ← `inquirer@7.3.3` ←
  `eslint@6.8.0` ← `rewire@5.0.0`. **Dev-only.**
- **Fix shipped:** the `rewire` bump below removed the `eslint@6.8.0` subtree
  (which pulled `inquirer → external-editor → tmp`); `tmp` is gone from the tree
  entirely.

---

## A single high-value follow-up: upgrade `rewire` — ✅ DONE 2026-06-29

`rewire@5.0.0` was a direct devDependency that dragged in the obsolete
`eslint@6.8.0` (rewire 5 depends on `eslint ^6.8.0`). That one subtree was the
sole source of **two** High alerts — `flatted@2.0.2` and `tmp@0.0.33`.

**Shipped (branch `linkify-it-markdown-it-upgrade`):** bumped `rewire ^5.0.0` →
`^9.0.1`. rewire 9 depends on `eslint ^9.30`, which dedupes with the project's
existing `eslint ^9.39.4`, so `eslint@6.8.0` and its whole subtree dropped out,
clearing both alerts at once. In practice `rewire` is not imported anywhere in
the repo, so the major bump carried no test-behavior risk (and the package could
reasonably be removed outright in a future cleanup). Verified: `eslint@6.8.0`,
`flatted@2.0.2`, `tmp`, `flat-cache@2`, `inquirer@7`, and `external-editor` are
all gone; full Jest suite, production build, and `yarn lint-non-build` all pass.

---

## Fixed on this branch

Committed individually as safe, in-range bumps (patched versions verified; Rails
boots, the production webpack build compiles, and the Jest suite passes):

| Package | Ecosystem | From → To | Kind |
|---|---|---|---|
| concurrent-ruby | rubygems | 1.3.6 → 1.3.7 | transitive, patch |
| faraday | rubygems | 2.14.2 → 2.14.3 | direct, patch |
| oj | rubygems | 3.17.0 → 3.17.3 | direct, patch (clears 10 high CVEs) |
| puma | rubygems | 7.2.0 → 7.2.1 | direct, patch (stayed off the 8.x major) |
| jwt | rubygems | 2.5.0 → 2.10.3 | transitive, minor |
| nokogiri | rubygems | 1.19.2 → 1.19.4 | direct, patch |
| form-data | npm | 3.0.4 → 3.0.5 | transitive resolution |
| fast-uri | npm | 3.1.0 → 3.1.3 | transitive resolution |
| @babel/plugin-transform-modules-systemjs | npm | 7.18.6 → 7.29.7 | transitive resolution |
| body-parser | npm | 1.20.0 → 1.20.5 | transitive resolution |
| path-to-regexp | npm | 0.1.7 → 0.1.13 and 1.8.0 → 1.9.0 | transitive resolutions |
| ws | npm | 7.5.10 → 7.5.11 and 8.19.0 → 8.21.0 | transitive resolutions |

Medium- and Low-severity alerts were out of scope for this pass and are not
tracked here.

---

*(This audit document was written by Claude Code, 2026-06-29.)*
