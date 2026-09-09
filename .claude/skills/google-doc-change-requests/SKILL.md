---
name: google-doc-change-requests
description: Turn a Google Doc of requested changes, downloaded as .docx, into an explicit change list — the visible text edits, the pending suggestions, and the decisions made in comment threads — before implementing any of it. Use this skill whenever the user hands over a .docx (or any Google Docs export) of team feedback, edits, or requested changes to copy, layout, or behavior.
---

# Google Doc change requests

A Google Doc that a team has been editing carries three layers, and only one
of them is the visible text:

1. **The text** — what the page says once every pending suggestion is accepted.
2. **Suggestions** — Google Docs "suggesting mode" edits, exported as tracked
   changes (`w:ins` / `w:del`), each with an author and a timestamp. Some are
   finished; some were mid-edit when the file was downloaded.
3. **Comments** — the margin discussion, exported to `word/comments.xml`, each
   anchored to a run of text. This is where decisions live: "editor's?",
   "Agreed, let's point to that", "they should be routed back to pick another
   claim", "feel free to delete".

`pandoc file.docx -t gfm` gives you layer 1 only: its default
`--track-changes=accept` applies every suggestion silently, and it drops every
comment. Working from that output alone misses whatever the team decided in
the margins. (It happened: four comment threads on the Fact Verification
exercise edits were missed on the first pass in September 2026, and one
half-finished suggestion had deleted a word from a sentence.)

Work through the phases in order. Do not start implementing before Phase 3.

## Phase 1: Extract all three layers

Work in the session scratchpad. `<file>` is the .docx the user provided.

```bash
mkdir -p "$SCRATCH/docx"
# 1. The final text, with images extracted (what the doc would say if every
#    pending suggestion were accepted).
pandoc "<file>" -t gfm --extract-media="$SCRATCH/docx" -o "$SCRATCH/docx/final.md"
# 2. Everything inline: insertions/deletions with author and date, and comment
#    anchors as spans. Use -t markdown (not gfm) so the spans keep attributes.
pandoc "<file>" --track-changes=all -t markdown -o "$SCRATCH/docx/all.md"
# 3. The ledger of comment threads (with anchored text) and suggestions.
bin/docx-changes "<file>"
```

Read all three. `all.md` shows where each suggestion and comment sits in the
flow; `bin/docx-changes` gives the threads with replies, authors and dates.
If it reports no comments and no suggestions, the doc is plain and `final.md`
is the whole story.

Images: pandoc extracts them to `$SCRATCH/docx/media/`. Note each one's
dimensions; team screenshots are usually full browser windows and will need
cropping to the passage that makes their point (Phase 4).

## Phase 2: Build the change ledger

Write a ledger (a markdown table in the scratchpad, or a `.claude/` plan file
if the work will span sessions) with one row per item, from four sources:

- **Text differences** — compare `final.md` against the current copy in the
  app (`config/locales/en.yml` etc.) and list each difference, quoting both
  sides. Copy from the doc is applied verbatim, typos included; note a
  suspected typo in the ledger rather than fixing it.
- **Suggestions** — one row each, from `bin/docx-changes`. Mark any whose
  result reads wrong (a lone deleted word, a sentence that no longer parses),
  and any timestamped within an hour or so of the download: those may have
  been mid-edit. Do not treat a pending suggestion as final if it garbles the
  text; put it to the user.
- **Comment threads** — one row each: anchored text, the thread (with
  replies and reactions), and a classification: *decided copy change*
  (someone agreed), *decided behavior change*, *open question* (no reply, or
  a question nobody answered), or *note to the operator* ("feel free to
  delete"). A behavior change is never implemented on the strength of a
  comment alone; see Phase 3.
- **Doc markers and omissions** — all-caps notes such as "SCREENSHOT OF
  VERIFIED" are placement notes, not copy; the doc usually walks one path
  through a flow, so anything in the current UI it doesn't mention (a
  conditional question, an alternate branch) is *keep unless told*, flagged.

Also note where the doc contradicts itself or its screenshots (a caption that
quotes different wording than the screenshot shows, a link the doc says to
replace but a sentence that still describes the old target).

## Phase 3: Confirm scope before building

Show the user the ledger — compactly: what will be applied verbatim, what
needs a decision, what is being left alone. Then:

- **Copy changes from the doc**, including agreed comment threads: proceed.
- **Behavior changes and open threads**: ask, in one message that lists them
  with a recommendation each. Different readings lead to materially different
  work, so this is worth the round trip.
- **Missing copy** (a heading the doc marks but doesn't write, alt text, a
  new sentence a behavior change needs): never write it. Leave a
  `[PLACEHOLDER - <what the copy needs to say>]` marker per CLAUDE.md, and list
  the placeholders for the user to fill. Where an existing operator-approved
  string already says the right thing (a button label, a link text), reuse it.

## Phase 4: Implement in reviewable pieces

The user usually wants to see each change on its own. Work as a series of
small commits, one per ledger group, each with before/after screenshots:

- Add a `SCREENSHOT=`-gated screenshot harness first if the feature lacks one
  (see Strategy A in `.claude/skills/prepare-pr/SKILL.md`). Commit it as the
  first, visually neutral commit; capture the baseline as `SCREENSHOT=00_master`.
- After each change: `yarn build` (copy edits need the i18n export it runs),
  then `SCREENSHOT=NN_<label> bundle exec rspec <harness spec>`; keep every
  `tmp/screenshots/NN_<label>/` so each commit's before is the previous
  commit's after. Delete the stray `<spec>__*.png` files the global
  screenshot hook adds alongside.
- Commit with the `commit` skill, `git commit --only <paths>`, so nothing
  else in the tree rides along.
- Images from the doc: crop to the passage that makes the point (ImageMagick
  `-crop`; join two strips with a hairline when the point spans a page),
  encode as WebP at native resolution, show at natural width rather than as
  two-up thumbnails, and link each to what it shows (a permalink to the
  article revision pictured; the source). If a screenshot can't be cropped
  into legibility, say so and offer to retake it (a PDF viewer's find bar can
  be reproduced headless with pdf.js + Selenium).
- Present the iterations together: a before/after gallery per commit (an
  Artifact, or `tmp/screenshots/gallery.html`) is what the user reviews.

## Phase 5: Report

Close with, in this order: what was applied (commit per ledger row), what
was deliberately not built and why, the placeholders awaiting copy (`grep -n
"\[PLACEHOLDER" config/locales/en.yml`), and the doc oddities preserved
verbatim. Keep the ledger's open rows in the PR's "Open questions" section.

## Gotchas

- `pandoc` defaults: `--track-changes=accept`, comments dropped. Always run
  the `--track-changes=all -t markdown` pass and `bin/docx-changes`.
- Google Docs exports a reply as a separate comment whose range opens inside
  the parent's; `bin/docx-changes` uses that nesting to show threads.
- A suggestion's author and timestamp tell you who decided and when; a
  deletion dated minutes before the download is probably unfinished.
- Doc text and doc screenshots can disagree (the doc quoted "started"; the
  screenshot said "launched"). Decide with the user which the app follows.
- The live Wikipedia article behind an example may already have changed;
  link permalinks (`oldid=`) to the revision the screenshot shows, found via
  the revision history, not the current page.
- Sources the team screenshotted may be paywalled (JSTOR). Link them anyway
  when the team wants students to see where the source lives, and ask the
  user for the file if a retake is needed.
