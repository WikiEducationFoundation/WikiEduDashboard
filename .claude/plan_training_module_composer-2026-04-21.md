# Training Module Composer — Plan

**Date:** 2026-04-21
**Author:** Sage + Claude (discussion-driven)

## Goal

Give admins a UI to prototype new training modules: compose a module slide-by-slide
(or bulk-paste prose content) in a realistic editor, save working drafts on the
server, and export the final module as a zip containing the canonical
`training_content/` yml files ready to drop into the repo.

Today, drafting happens in Google Docs and `.yml` file creation is hand work.
The composer replaces the hand-work step.

## Scope

**In scope (initial version):**
- Admin-only UI at a new route
- List, create, open, rename, delete drafts
- Slide list sidebar (PowerPoint-style) + slide editor pane with markdown content + title
- Add / delete / reorder (drag-and-drop) slides
- Paste a markdown blob with `## Title`-delimited slides to bulk-create slides
- Live markdown preview of the current slide that visually resembles the production slide
- Save draft → single yml file on server
- Export draft → zip containing production-layout yml files
- Automatic id allocation (module id and slide ids)
- Automatic slug prepopulation from title, editable

**Explicitly out of scope (may come later):**
- Assessment / quiz slides (display or editing)
- Editing library yml files — admin manually adds the new module to a library after export
- Translations / i18n
- Autosave
- Multi-user simultaneous editing on one draft (last save wins)
- Previewing full module flow through `/training/...` routes (we render inline instead)
- Auto-opening a PR with the generated files

## Design decisions (agreed upfront)

1. **Drafts are yml files on the server**, not DB rows. Any admin can list drafts, choose one, and pick up editing.
2. **Single yml file per draft** (not the mirrored production layout) — simpler, atomic save, easy to hand-edit if needed. Export converts it to production layout.
3. **Preview is inline**, using the existing `markdown_it` util. No routing through `/training/...`, no temporary DB rows.
4. **Paste format**: `##`-prefixed h2 = slide title, content until next `##` = that slide's markdown content. Invalid input is rejected with a clear error.
5. **Export = zip download** in production layout.
6. **IDs assigned automatically**, refreshed on each save (so reorder → renumber). Module id = `max(existing module ids + other draft module ids) + 1`. Slide id = `module_id * 100 + position` (1-indexed).
7. **Slugs** prepopulate from title via Rails `parameterize`, but stay editable. Slide slugs must be unique across the whole system (production slides + all drafts) — we warn at save and block at export.
8. **No quiz support yet**; the data model leaves room to add assessment slides later.

## Draft yml schema (on server)

Single file per draft at `training_content_drafts/<draft-slug>.yml`:

```yaml
slug: my-new-module             # draft identifier, matches filename
name: My new module
description: |
  Module description...
estimated_ttc: 15-25 minutes
module_id: 75                   # allocated on first save
slides:
  - slug: intro
    title: Introduction
    content: |
      Welcome to the module...
  - slug: second-slide
    title: Second slide
    content: |
      More content...
```

No `id:` stored per slide — slide ids are derived from position at export time
(and at preview time, if needed). This avoids drift across reorders.

### Draft directory location

`training_content_drafts/` sibling to `training_content/`.

**Deployment note:** On Capistrano-deployed hosts the release dir is replaced on
each deploy. The directory must live under `shared/` and be symlinked into each
release (add to `deploy.rb`'s `linked_dirs`). Add `training_content_drafts/` to
`.gitignore`.

## Backend

### Routes (admin-only)

```
GET    /admin/training_module_drafts              # index UI (HTML shell, React mounts)
POST   /admin/training_module_drafts              # create new draft
GET    /admin/training_module_drafts/:slug        # JSON: draft content
PATCH  /admin/training_module_drafts/:slug        # save draft (full replace)
DELETE /admin/training_module_drafts/:slug        # delete draft
GET    /admin/training_module_drafts/:slug/export # zip download
POST   /admin/training_module_drafts/:slug/parse_paste  # (optional server-side parsing; can be client-side)
```

All routes protected by `before_action :require_admin_permissions` (same
pattern as `admin_course_notes_controller.rb`).

Controller: `TrainingModuleDraftsController` (non-namespaced class, admin-gated
— matches existing style in this repo).

### Services (all new, in `app/services/`)

- `ListTrainingModuleDrafts` — returns `[{slug, name, updated_at}, …]` from disk
- `LoadTrainingModuleDraft(slug)` — reads and returns the yml as a hash
- `SaveTrainingModuleDraft(slug, attrs)` — validates, allocates/refreshes `module_id`, writes yml atomically (write to tmp file, rename)
- `DeleteTrainingModuleDraft(slug)` — removes the file
- `ParseSlidesFromMarkdown(markdown)` — splits on top-level `## ` headings, returns `[{title, slug, content}, …]`. Raises on invalid input. Also used client-side (JS port), but the spec-covered Ruby version is the source of truth.
- `ExportTrainingModuleDraft(slug)` — builds a `StringIO` zip with:
  - `modules/<slug>.yml` — module manifest
  - `slides/<module_id>-<slug>/<NNNN>-<slide-slug>.yml` — one per slide (ids 4-digit zero-padded)
- `AllocateTrainingModuleId` — computes the next id given existing DB rows + other draft files
- `CheckSlideSlugCollisions(draft)` — returns list of collisions against `TrainingSlide.pluck(:slug)` and other drafts' slugs

Filename convention for export: `<module_id>-<slug>/` uses hyphens
(matches the modern convention in `training_content/wiki_ed/slides/` —
e.g. `21-wikipedia-policies-professional`, not the older underscore form).

### Slug prepopulation

Rails `"Five Pillars quiz".parameterize` → `five-pillars-quiz`. Good enough.
User can edit.

## Frontend

### Location

`app/assets/javascripts/training_module_composer/`
- `index.jsx` — mount point, router
- `components/DraftList.jsx` — landing page with list + "new draft" button
- `components/DraftComposer.jsx` — main editor shell
- `components/SlideSidebar.jsx` — scrollable slide list with drag-drop
- `components/SlideEditor.jsx` — title + slug + markdown textarea + live preview
- `components/PasteImportModal.jsx` — bulk paste dialog
- `components/ModuleMetadataForm.jsx` — module name, description, ttc, slug
- `utils/parse_paste.js` — client-side mirror of `ParseSlidesFromMarkdown`
- `utils/slide_preview.js` — render markdown via existing `markdown_it` util, wrap in production slide classes

Drag-and-drop: use `react-dnd` + `react-dnd-html5-backend` (already in `package.json`).

### Preview

For the "realistic training module UI" feel, render the slide with the same
CSS classes as the real training slide (`.training__slide__content`, etc.),
passing title + rendered markdown. Do **not** wire up navigation, progress, or
the quiz component. Goal: the prose looks the way it will in production.

### Entry point

Add a link in the admin tools menu (wherever other admin-only tools live —
confirm location during implementation).

## Paste parsing contract

Input: markdown string. Output: `[{title, slug, content}, …]`.

Rules:
- Split on lines matching `/\A##\s+(.+)\z/` (single pass, line-by-line).
- The first non-empty line must be an `##` heading. Otherwise reject with:
  `"Invalid paste format: expected first line to be an ## heading."`
- Content of each slide is everything between its heading and the next heading,
  stripped of leading/trailing blank lines.
- Slug: `parameterize(title)`.
- Empty content is allowed (title-only slides are valid).

## Export zip structure

For a draft with `module_id: 75`, `slug: my-new-module`, 3 slides:

```
modules/my-new-module.yml
slides/75-my-new-module/7501-intro.yml
slides/75-my-new-module/7502-second-slide.yml
slides/75-my-new-module/7503-third-slide.yml
```

`modules/my-new-module.yml`:
```yaml
name: My new module
id: 75
description: |
  ...
estimated_ttc: 15-25 minutes
slides:
  - slug: intro
  - slug: second-slide
  - slug: third-slide
```

Slide file `7501-intro.yml`:
```yaml
id: 7501
title: Introduction
summary:
content: |
  Welcome...
```

Zip is streamed from `StringIO` via `rubyzip` (already a dependency — verify during implementation).

## ID allocation

On save:
1. `existing_ids = TrainingModule.pluck(:id) + other_draft_module_ids`
2. If the draft already has a `module_id` and it's still unique, keep it.
3. Otherwise `module_id = existing_ids.max + 1`.
4. Slide ids are not stored — they are always `module_id * 100 + position` at export/preview time.

Edge case: if another draft is saved between load and save of the current draft,
and they both end up with the same reserved id, the save attempting to use a
taken id re-allocates silently. Acceptable given low concurrency.

## Tests

- **Service specs** (`spec/services/`):
  - `parse_slides_from_markdown_spec.rb` — valid input, invalid (no headings), empty, unicode titles, code fences with `##` inside (tricky — test explicitly)
  - `save_training_module_draft_spec.rb` — roundtrip, id allocation, atomic write
  - `export_training_module_draft_spec.rb` — zip structure, content, filename padding, slug collision detection
- **Controller spec** (`spec/controllers/training_module_drafts_controller_spec.rb`) — admin gate, CRUD endpoints, zip response
- **Feature spec** (`spec/features/training_module_composer_spec.rb`) — create draft, paste markdown, reorder, save, export, assert zip contents

## Phased build order

1. **Backend scaffold** — controller, routes, admin gate, services, service specs. Draft dir configured. Can save/load/list/delete via curl.
2. **Export** — zip generation service + endpoint + spec. Produces valid production-layout files.
3. **Frontend scaffold** — draft list + composer shell + module metadata form + single-slide editor + save.
4. **Slide operations** — add, delete, reorder (drag-drop), slug prepopulation, live markdown preview.
5. **Paste import** — modal + parser + replace-slides flow with confirmation.
6. **Polish** — empty states, validation messages, slug-collision warnings, a link into the composer from the admin UI.

Each phase ends with a working product; after phase 3 you can compose and
export a module (just slower, without paste or drag-drop). Ship to production
whenever a phase is good enough.

## Open questions / to verify during implementation

- Admin-menu entry point location (where to link from)
- Confirm `rubyzip` is already a dependency
- Confirm the exact `before_action` used on other admin-only controllers
- Check whether any existing slide slugs collide with names commonly chosen for drafts — probably not worth addressing until we hit it

## Non-goals / anti-patterns to avoid

- Don't add a DB model for drafts. Files on disk are the single source of truth.
- Don't auto-commit or auto-PR the generated files. Admin downloads the zip and commits manually (standard repo workflow).
- Don't try to edit library yml files from the composer. That's a separate, simpler hand-edit.
- Don't reuse `training_slide_handler.jsx` for preview — it's tightly coupled to Redux + router. Build a small standalone preview component that shares CSS classes.
