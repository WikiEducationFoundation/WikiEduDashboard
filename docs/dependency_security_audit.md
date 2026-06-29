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

### 1. tinymce (no fixed release exists)

- **Alerts (all high, XSS):** GHSA-vg35-5wq7-3x7w (media plugin
  `data-mce-object` injection), GHSA-v98h-vmpc-fpqv (`mce:protected` comments),
  GHSA-q742-qvgc-gc2f (`data-mce-` prefixed `src`/`href`/`style`).
- **Range / patch:** `< 5.11.1`; **`first_patched_version` is null** — there is
  no patched release on the TinyMCE 5.x line.
- **Current:** `tinymce ^5.2.2` (direct dependency) plus
  `@tinymce/tinymce-react ^3.12.6`, which only supports TinyMCE 5.
- **Why deferred:** No 5.x fix is available. Clearing these requires migrating to
  TinyMCE 6 or 7 — a major editor API change that also forces an upgrade of
  `@tinymce/tinymce-react` (to v4/v5). TinyMCE 6+ additionally changed its
  licensing model (self-hosted open-source build still exists but warrants a
  deliberate review).
- **Recommended:** Scope a TinyMCE 5 → 7 migration as its own project. In the
  interim, assess real exposure: check whether the affected plugins/attribute
  paths (notably the `media` plugin) are actually enabled in our editor config,
  and whether output sanitization (DOMPurify) already neutralizes these vectors.
- **Risk:** Editor is user-facing; XSS is real if the vulnerable surfaces are
  reachable. Exposure depends on our specific TinyMCE configuration — needs
  review before prioritizing.

### 2. linkify-it (needs markdown-it major upgrade)

- **Alert:** GHSA-22p9-wv53-3rq4 (high) — quadratic ReDoS in `LinkifyIt#match`.
- **Range / patch:** `<= 5.0.0`, patched `5.0.1`.
- **Current:** `linkify-it 3.0.3`, pulled **only** by `markdown-it@12.3.2`
  (direct dependency `markdown-it ^12.3.2`).
- **Why deferred:** `linkify-it` is required by `markdown-it`; the 12.x line uses
  `linkify-it` 3.x. Forcing `linkify-it` 5.x under markdown-it 12 would break it
  (API differs across the 3 → 5 majors). The clean fix is bumping
  `markdown-it` 12 → 14, which uses `linkify-it` 5.x and also clears the separate
  **medium** markdown-it alert #389 (patched `14.2.0`).
- **Recommended:** Upgrade `markdown-it ^12.3.2` → `^14.x` together with a
  compatible `markdown-it-footnote`, then regression-check rendered markdown
  (used in haml templates/helpers; confirm whether any user-supplied markdown is
  rendered). markdown-it 12 → 14 has output and plugin-API changes.
- **Risk:** ReDoS (DoS) on inputs run through the linkifier; moderate.

### 3. js-cookie (needs react-cookie-consent upgrade)

- **Alert:** GHSA-qjx8-664m-686j (high) — per-instance prototype hijack in
  `assign()` enabling cookie-attribute injection.
- **Range / patch:** `<= 3.0.5`, patched `3.0.7`.
- **Current:** `js-cookie 2.2.1`, pulled by `react-cookie-consent@8.0.1`
  (`js-cookie ^2.2.1`). **Runtime** — the cookie-consent banner.
- **Why deferred:** `js-cookie` 2 → 3 is a major API change.
  `react-cookie-consent@8.0.1` expects js-cookie 2.x; forcing 3.x via a
  resolution could break the consent banner in the browser.
- **Recommended:** Upgrade `react-cookie-consent` to a release that depends on
  js-cookie 3.x, then functionally verify the cookie-consent banner (set/read/
  expiry behavior).
- **Risk:** Runtime, but the attack requires control over cookie-attribute input;
  low-to-moderate. Still, a functional check of the banner is required.

### 4. tar (only patched on the 7.x line; cacache pins 6.x)

- **Alerts (all high):** GHSA-9ppj-qmqm-q256, GHSA-qffp-2rhf-9h96,
  GHSA-83g3-92jg-28cx, GHSA-34x7-hfp2-rc4v, GHSA-r6q2-hw4h-h46w,
  GHSA-8qq5-rm4j-mr97 — symlink/hardlink path traversal and extraction race
  conditions in node-tar.
- **Range / patch:** Various, with patched versions **only** on the 7.5.x line
  (e.g. `7.5.7`, `7.5.8`, … up to `7.5.16`). Our installed `tar 6.2.1` is matched
  by these ranges.
- **Current:** `tar 6.2.1`, held by the existing resolution `"tar": "^6.2.1"`;
  required by `cacache@16.1.1` (`tar ^6.2.1`) and `node-gyp@9.0.0`.
  **Build/install-time only** — used for native-module build caching, not in the
  running server or the browser bundle, and we do not extract untrusted archives
  at runtime.
- **Why deferred:** The only patched line is tar 7.x. `cacache@16` pins
  `tar ^6.2.1`; forcing tar 7 via a resolution risks breaking cacache/node-gyp
  (the tar 6 → 7 API changed). The robust fix is upgrading the toolchain that
  pulls `cacache@16` / `node-gyp@9` so it depends on tar 7.
- **Recommended:** Either (a) bump the `node-gyp`/`cacache` chain to versions
  that use tar 7, or (b) change the resolution `"tar"` → `^7.5.16` and verify a
  clean `yarn install` with native dependency builds. Verify before merging.
- **Risk:** **Low** real-world exposure (build-time, no untrusted archives), but
  this is the single largest cluster of open High alerts.

### 5. serialize-javascript (needs css-minimizer-webpack-plugin upgrade)

- **Alert:** GHSA-5c6j-r48x-rmvq (high) — RCE via `RegExp.flags` /
  `Date.prototype.toISOString()`.
- **Range / patch:** `<= 7.0.2` (high) and `< 7.0.5` (medium); patched `7.0.3` /
  `7.0.5`.
- **Current:** `serialize-javascript 6.0.0`, pulled by
  `css-minimizer-webpack-plugin@4.0.0` (`serialize-javascript ^6.0.0`).
  **Build-time only** — serializes the build/minifier config, not attacker input.
- **Why deferred:** 6 → 7 is a major bump and `css-minimizer-webpack-plugin@4`
  expects `^6.0.0`; forcing 7.x could break the minifier.
- **Recommended:** Bump `css-minimizer-webpack-plugin` (direct dependency) to a
  release that uses serialize-javascript 7.x and verify the production CSS build.
- **Risk:** **Low** (build-time, no untrusted input).

### 6. flatted (legacy 2.x line) — shares a fix with tmp

- **Alerts (high):** GHSA-rf6f-7fwh-wjgh (`<= 3.4.1`, prototype pollution),
  GHSA-25h7-pfq9-p65f (`< 3.4.0`, unbounded-recursion DoS).
- **Note:** The project's **3.x** flatted line is already pinned to `3.4.2`
  (patched) via the existing `"flatted@^3.1.0": "^3.4.2"` resolution. Only the
  legacy **`flatted 2.0.2`** copy remains vulnerable.
- **Current chain:** `flatted 2.0.2` ← `flat-cache@2.0.1` ←
  `file-entry-cache@5.0.1` ← `eslint@6.8.0` ← **`rewire@5.0.0`** (direct
  devDependency). **Dev-only** (lint/test caching).
- **Why deferred:** Forcing flatted 3.x onto `flat-cache@2` (which uses the
  flatted 2.x API) would break it.
- **Recommended fix (shared with tmp below):** Upgrade `rewire ^5.0.0` → `^9.0.1`.
  rewire 5 depends on the ancient `eslint ^6.8.0`; rewire 9.0.1 instead depends on
  `eslint ^9.30`, which matches the project's existing `eslint ^9.39.4` direct
  dependency. Bumping rewire therefore lets eslint dedupe to the modern 9.x copy
  and drops the entire `eslint@6.8.0` subtree — including `flat-cache@2` /
  `flatted@2` **and** `inquirer@7` / `external-editor` / `tmp` (see below).
  Verify rewire-based tests still pass after the bump (rewire spans the 5 → 9
  majors, so confirm the resulting tree and re-run the JS suite).
- **Risk:** **Low** (dev-only).

### 7. tmp — shares a fix with flatted (rewire)

- **Alert:** GHSA-ph9p-34f9-6g65 (high) — path traversal via unsanitized
  prefix/postfix enabling directory escape.
- **Range / patch:** `< 0.2.6`, patched `0.2.6`.
- **Current chain:** `tmp 0.0.33` ← `external-editor@3.1.0` ← `inquirer@7.3.3` ←
  `eslint@6.8.0` ← **`rewire@5.0.0`** (direct devDependency). **Dev-only.**
- **Why deferred:** `external-editor@3.1.0` pins `tmp ^0.0.33`; forcing 0.2.6
  could break it.
- **Recommended fix:** Same as flatted — upgrade `rewire` 5 → 7 to drop the
  `eslint@6.8.0` subtree that pulls `inquirer → external-editor → tmp`.
- **Risk:** **Low** (dev-only).

---

## A single high-value follow-up: upgrade `rewire`

`rewire@5.0.0` is a direct devDependency that drags in the obsolete
`eslint@6.8.0` (rewire 5 depends on `eslint ^6.8.0`). That one subtree is the
sole source of **two** High alerts — `flatted@2.0.2` and `tmp@0.0.33`.

The project already uses `eslint ^9.39.4` directly, and `rewire@9.0.1` depends on
`eslint ^9.30`. So bumping `rewire ^5.0.0` → `^9.0.1` in `package.json` lets
eslint dedupe to the existing 9.x copy, removing `eslint@6.8.0` and the whole
vulnerable subtree below it, clearing both alerts at once. It was left out of the
"safe and simple" commits only because it is a direct-dependency bump across
several majors (5 → 9) touching test infrastructure (rewire is used in tests for
module mocking), so it deserves its own verification pass with the full JS suite.

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
