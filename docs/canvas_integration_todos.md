# Canvas integration — follow-ups

Deferred items from the Canvas / LTI integration work. None are blockers for the
current staging walkthrough; revisit as noted.

## Privacy / anonymized mode

Decision: **anonymized ("None (Anonymized)") is the main supported mode**, and
launch + Wikipedia OAuth is the only linking path.

- [ ] **Roster legibility.** In anonymized mode, students who haven't launched yet
  appear in the instructor/staff LMS panels as bare Canvas user IDs (no name/email).
  Once a student launches and links via Wikipedia OAuth they show by their Wikipedia
  identity, so only *pending* members are opaque. Explore surfacing something more
  legible for unlinked members.
- [x] **Data-sharing copy.** _(Done 2026-07-24.)_ The data-sharing statements in
  `docs/canvas_integration_guide.md`, `docs/hecvat.md`, and
  `docs/canvas_dev_setup.md` now say the Dashboard receives only an **opaque LMS
  user id + role — no names or emails**; identity comes from the student's own
  Wikipedia OAuth. (Final compliance wording is still the operator's to confirm.)
- [x] **`auto_link_by_email` is now unused → removed.** _(Done 2026-07-24.)_
  Hardened to a true anonymized posture: `normalize_member` keeps only id/roles/
  status, `LtiSession`/`LtiMemberLinker` no longer read or store name/email,
  `auto_link_by_email` is gone (members link only via their own Wikipedia OAuth),
  and a migration dropped `lti_contexts.name`/`.email`.

## Admin registration UX

- [ ] **Placement Title / Icon URL.** The dynamic-registration "Register App" dialog
  shows empty **Title** and **Icon URL** fields per placement, and a blank Title
  falls back to the tool's internal name (e.g. "wikiedu.org testing"). LTIAAS does
  **not** appear to expose per-placement titles/icons (only the overall tool logo),
  so the admin has to set the Title during registration. Therefore: (a) the guide
  must document the Title field and recommend a value ("Wiki Education Dashboard"),
  and (b) double-check whether LTIAAS supports per-placement `text`/`icon_url` via
  some other config path.

- [ ] **LTIAAS config: add `course_navigation`, `default: disabled`.** Dynamic
  registration sources placements from the LTIAAS config, which initially lacked
  `course_navigation` (the old manual keys set placements directly in Canvas, so the
  config never needed it). It's now been added to the config — but it also needs
  `default: disabled` so the nav link is **opt-in**. Otherwise it defaults to
  enabled and appears in *every* course the moment the tool is made available (had
  to fix this on the installed tool via the Canvas API during the walkthrough). Set
  both in the LTIAAS config so future institutions' registrations come out correct.
  Also add `link_selection` etc. if desired.
- [ ] **Guide: install shortcut + optional titles.** Point the guide at the "View
  in Canvas Apps" link (from the dev key's Client ID column) as the easy route to
  install/manage the app, and note the placement Title/Icon fields are optional —
  leave blank to use the tool's LTIAAS name + logo. (Fold in once the placement set
  is sorted, so the install section is revised once.)

## Linking / launch model (design)

- [x] **Deep-link-first is now the model (decided + shipped 2026-07-23).** Per
  operator direction, the gradebook-layout radios were removed from the setup
  step entirely — linking a course just links it. New bindings default to
  `lumped` (auto-create nothing); the instructor imports every column (account
  indicator, trainings roll-up, exercises) via the Modules "Import Wikipedia
  assignments" flow, and `SyncLtiLineItems` discovers + binds them.
  - **Vestigial follow-up:** `standard`/`per_block` (auto-create) remain as
    valid `gradebook_granularity` values with working code, but are no longer
    user-selectable (retained only so existing rows / the gradebook & full-course
    screenshot galleries keep working — those galleries force `standard` via
    `DashboardAdminClient.set_granularity` as a shortcut). Removing
    standard/per_block entirely (and reworking those two galleries onto the
    deep-link import flow) is the remaining cleanup. `gradebook_granularity`
    could then collapse to a boolean or be dropped.

- [ ] **Bulk deep-linking via `module_index_menu_modal` (built; working).** The
  import flow works end-to-end (verified: one submit → one published module
  with all nine assignments). The created module's default name is Canvas's
  "New Content From App"; Canvas reads a tool-settable override from the
  deep-linking response JWT claim
  `https://canvas.instructure.com/lti/module_name` (found in
  `deep_linking_services.rb`), which we send ("Research and write a Wikipedia
  article", operator-supplied) — but LTIAAS drops it. **Confirmed 2026-07-24 by
  decoding the actual signed DeepLinkingResponse JWT LTIAAS returned:** all nine
  content items are present, but the top-level `.../lti/module_name` claim is
  absent (no key containing "module" at all). LTIAAS support says they "pass
  through all extra content" and suspect a formatting issue; the reply-back with
  the exact request object + the decoded JWT is drafted, asking where they want a
  top-level DeepLinkingResponse claim in the request body. We keep sending the
  claim (harmless; a 200, no fallback fires) so it starts working if/when LTIAAS
  passes it through. Until then, the guide should note instructors can rename the
  module after import. Until then, the guide
  should note instructors can rename the module after import. Assignment
  descriptions pull from existing Dashboard content (block body → module
  catalog descriptions; the roll-up lists its training modules); only the
  setup column's description is still a `[PLACEHOLDER]`. (Background: true
  server-side creation is impossible — a deep-linking response must POST
  through the instructor's browser to a launch-specific return URL — which is
  why the flow is one-click-bulk rather than automatic.) Remaining: verify the
  module_name pass-through live, and add `module_index_menu_modal` to the
  LTIAAS config so future registrations carry it (the staging tool got it via
  a Canvas API edit only).

- [ ] **Consider a nav-link-free, deep-link-first linking model.** The
  course-navigation link is heavyweight for what is mainly a one-time instructor
  action (linking the course). Explore linking via the `assignment_selection`
  deep-link placement instead: the instructor links the course the first time they
  add a Dashboard assignment, and students launch/enroll via those assignments — no
  persistent course-nav item. Requires code changes: the bind
  (`handle_instructor_launch`) and student enroll (`handle_student_launch`)
  currently fire on the course-navigation launch and would need to fire from the
  deep-link / assignment launches. Note: the core machinery (binding, NRPS roster
  sync, AGS grade passback) is unchanged — only the entry point moves. A pure
  Dashboard-initiated "enter your Canvas course URL" flow is also possible for the
  data sync, but has an authorization gap (the launch is what proves the user
  teaches that course), so it needs a solution to that before it's viable.

## UX rough edges

- [x] **Gradebook no longer reports not-started students as failing.**
  _(Fixed on CanvasStaging.)_ A UX review found that an unconnected student read
  **Total 0%** — our onboarding/milestone columns are graded points columns, and
  a pushed 0 counts as a failing 0%. Canvas offers **no LTI way** to make these
  columns Complete/Incomplete or omit-from-final-grade (only the `submission_type`
  AGS extension is writable — confirmed against `lti/ims/line_items_controller.rb`
  and `deep_linking_controller.rb`), so the only lever is which scores we post.
  Fix: `SyncLtiGrades#skip_zero?` no longer seeds a fresh 0 for not-done /
  not-connected work (Canvas excludes ungraded items from the total by default);
  a connected student still gets 1.0, and a genuine downward correction (a
  previously-positive score going to 0) still posts. **This supersedes the
  earlier design that pushed 0.0 = "not connected" for every student** — the
  who-hasn't-connected signal now lives in the in-Canvas "Wikipedia account"
  roster instead. _Operator decision to confirm:_ this is the only way to avoid
  the failing-grade signal given Canvas's constraints; the alternative (accept
  0% in the total to keep the gradebook nudge) is worse.

- [ ] **Trainings/exercise rosters: N×M queries.** The in-Canvas trainings roster
  computes `LtiTrainingProgress` per student (each doing a `TrainingModulesUsers`
  lookup per module) and `LtiBlockProgress` has the same per-row shape — fine at
  walkthrough scale, worth batching before real course sizes.
  - _LMS-name identity: resolved 2026-07-24._ The anonymization removed
    `LtiContext#name`, so all three rosters now show the Wikipedia username (the
    setup roster still shows the CoursesUsers real name for connected students).

- [ ] **Score-comment attribution shows "- Someone" (platform limitation).**
  AGS score comments ("1 of 19 trainings completed", the setup "✓") are
  created "with an unknown author" per Canvas's Score API docs; "Someone" is
  Canvas's UI label for authorless comments and no AGS field can set it.
  Option if wanted: append an origin ("— dashboard.wikiedu.org") to the
  comment text itself, though Canvas still renders its own "- Someone" line
  beneath.

- [~] **Assignments show "No additional details" in Canvas (by design now).**
  Canvas shows "No additional details were added for this assignment" on every
  imported column, and there's no way around it in-assignment: the AGS line-item
  API has no description field, and deep-linked content items _could_ carry a
  `text` description but **we deliberately don't send one** —
  `BuildLtiDeepLinkForm` sets no `text` (operator decision 2026-07-21), because a
  baked-in description goes stale the moment the Dashboard timeline changes.
  Instead the descriptive content renders **live in the iframe drill-down** (block
  body, roll-up module list, exercise instructions), which is always current. So
  the empty Canvas description is intentional, not a gap. No action unless we
  decide a short static blurb is worth the staleness.

- [ ] **Rejected / pre-activation launch shows raw JSON.** Launching before LTIAAS
  activates the registration (or any LTIAAS-rejected launch) surfaces a raw JSON
  error in the Canvas iframe — LTIAAS returns it before the launch reaches our app,
  so we can't render a friendly page. Manageable since Wiki Education controls
  activation timing, but: document "activate before instructors launch," and check
  whether LTIAAS can present a friendlier pre-activation message.

## Instructor launch UX

- [x] **Post-link launch shows no confirmation / sync status.** _(Implemented on
  CanvasStaging; copy placeholders pending.)_ The bound-course nav launch now
  renders `lti_launch/instructor_status` in the iframe instead of redirecting into
  the full dashboard (which read logged-out there due to cookie partitioning):
  link confirmation, Dashboard course link (new tab), synced-student count, and
  last-sync time via the new `LtiSyncStatus` service — shared with
  `LmsIntegrationStatusController` so the sidebar and launch view can't disagree.
  Header/explanation/error strings are `[PLACEHOLDER]`s in `en.yml` awaiting
  operator copy.

- [x] **Setup + trainings assignment launches show the empty/orphan panel.**
  _(Implemented on CanvasStaging; copy placeholders pending.)_
  `render_assignment_view` (now in the `LtiAssignmentViews` concern) dispatches on
  `gradable_type`: SETUP renders an account-connection roster (not-yet-connected
  members listed first, opaque-id fallback for anonymized unlinked rows) via
  `SetupAssignmentViewContext`; TRAINING_PROGRESS renders per-student
  "X of Y trainings completed" via `TrainingsAssignmentViewContext` (counts from
  `LtiTrainingProgress`, same as the pushed grades). Students see their own
  status; the trainings view links out to the course timeline. Summary/hint
  strings are `[PLACEHOLDER]`s awaiting operator copy.

- [x] **Sync granularity: expand to three options (decided).** _(Implemented on
  CanvasStaging.)_ Internal mode names: `standard` (option 1, new default —
  trainings roll-up + auto per-exercise columns), `per_block` (option 2,
  unchanged), `lumped` (option 3, unchanged: roll-up + manual deep-linked
  exercises — matching how existing rows actually behaved, so no data migration;
  only the column default changed). Setup radios render from
  `GRADEBOOK_GRANULARITIES` order with the recommended mode first/preselected.
  The old `lumped` radio label already described option 1's behavior, so that
  copy moved to `standard`; the `lumped` label + example are `[PLACEHOLDER]`s.
  Also fixed while in there: `AssignmentViewContext` hardcoded
  `exercises_only: true`, so per_block rosters could disagree with the gradebook —
  both now key off `LtiCourseBinding#rolled_up_trainings?`. Remaining (ops):
  re-sync existing staging bindings after deploy, flipping any that should use
  the new `standard` mode.

- [x] **Assignment + nav launches render in-iframe without a Dashboard
  session.** _(Implemented on CanvasStaging.)_ Inside the Canvas iframe there
  is never a Rails session (partitioned cookies), so every launch used to show
  the generic "open in a new tab" landing. The ltik itself authenticates the
  launch (the deep-link picker already relied on this), so `LtiAnonymousLaunch`
  now renders the read-only views directly in the iframe: assignment
  drill-downs (viewer resolved from the launch's LTI identity via LtiContext)
  and the bound-course instructor status view. The landing remains only for
  account-dependent flows: setup on an unlinked course (with the operator's
  "not yet linked" notice for instructors) and students who haven't connected
  a Wikipedia account yet.

- [x] **No UI to change gradebook layout after linking.** _(Moot as of the
  deep-link-first change, 2026-07-23.)_ The setup step no longer offers a
  gradebook-layout choice at all — linking just links, and columns are imported
  via Modules — so there's nothing to change post-link and no "you can change
  this later" promise. Revisit only if `standard`/`per_block` ever become
  user-selectable again.

## Deep-link picker (`DeepLinkableGradables`)

- [x] **Picker list isn't in timeline order.** _(Fixed on CanvasStaging.)_
  `gradable_blocks` now sorts by `week.order` then `block.order` in both
  `DeepLinkableGradables` (picker) and `SyncLtiLineItems` (auto-created columns —
  Canvas lists assignments in creation order, so creation must walk the
  timeline). Note: already-created Canvas assignments keep their positions; the
  order fix shows only for columns created after it deployed.
- [x] **Picker offers the trainings roll-up even though it's auto-created.**
  _(Moot as of deep-link-first, 2026-07-23.)_ In `lumped` (the only mode setup
  now produces) nothing is auto-created, so the picker offering the roll-up is
  correct — it's how the instructor imports that column. The duplicate risk only
  existed under `standard`/`per_block` auto-create, which are no longer
  user-selectable. Revisit if those modes return.

## Bugs (found during the walkthrough)

- [x] **500 when linking an already-linked Dashboard course.** _(Fixed on CanvasStaging.)_ `lti_course_bindings`
  has a unique DB index on `course_id` (`index_lti_course_bindings_on_course_id_unique`)
  but no matching model validation, and the setup picker (`@user_courses =
  current_user.instructed_courses`) doesn't exclude already-linked courses. Selecting
  a course that's already bound → `RecordNotUnique` in `complete_setup`'s `update!`
  → uncaught → 500. Fix: (a) filter/disable already-linked courses in the setup
  picker, and (b) add the model uniqueness validation + a rescue in `complete_setup`
  so it degrades to a friendly message rather than a 500.
- [x] **"View in Canvas" link 404s — uses the raw LTI context id.** _(Fixed on CanvasStaging.)_
  `LmsIntegrationStatusController#lms_course_url` (line 55) builds
  `<platform_url>/courses/<lms_context_id>`, but `lms_context_id` is the opaque LTI
  context id, not Canvas's numeric course id — so Canvas 404s ("Couldn't find Course
  with API id ..."). Fix: use Canvas's `lti_context_id:` lookup prefix —
  `<platform_url>/courses/lti_context_id:<lms_context_id>`. Verified on live Canvas:
  bare id → 404, prefixed → 200 (course 178). Also confirm `lms_platform_url` is the
  institution's actual Canvas web host (not a generic `canvas.instructure.com`
  issuer) when testing a hosted institution, or the link host will be wrong.
- [x] **Deep-linked exercise shows the orphan view on first launch.** _(Fixed —
  both proposed fixes are in place.)_ (a) `LtiDeepLinking#deep_link_select`
  schedules `LtiLineItemSyncWorker.perform_in(2.minutes, binding.id)`, so the new
  column is discovered + bound shortly after creation; and (b)
  `ResolveAssignmentLineItem#bind_from_launch_line_item` discovers the line item
  by tag via AGS (lists line items, reads the launch line item's `tag`, matches
  the gradable's `resource`) and binds/repoints the local row — so a launch that
  carries the AGS `lineItemId` resolves immediately, even before the 2-minute
  sync. Only a launch that carries neither the marker nor a scoped `lineItemId`
  falls through to orphan until the sync runs.

## Housekeeping (after the walkthrough)

- [x] **Re-point the staging specs.** _(Done 2026-07-22.)_ The harness + `spec/staging/`
  specs now target the current **"wikiedu.org testing" (tool 5)** registration via
  `LaunchHelpers#tool_label` (override `CANVAS_TOOL_LABEL`), and were reworked for the
  deep-link-first model (Modules-page bulk import, in-iframe drill-downs). Gallery
  rebuilt and extended since: **37 shots, 8 flows, all green** (added the
  fact-verification exercise flow — not-started / in-progress / instructor
  roster — plus the student progress overview and the grade-sync surfaces).
- [ ] **Finalize guide placeholders.** `docs/hecvat.md` is clean; the dev guide's
  guide/HECVAT links are filled; the manual-path config source is gone (manual
  path removed). Remaining `[PLACEHOLDER]`s are all operator copy in
  `docs/canvas_integration_guide.md`: the fuller data-sharing summary, the two
  troubleshooting specifics (refused-to-connect, sync timing), and the
  support/activation contact.
- [x] **Fill the launch-view copy placeholders.** _(Done — `grep '\[PLACEHOLDER'
  config/locales/en.yml` now returns nothing.)_ The operator filled the grade-sync
  started/error notices, the import next-step, the post-link flash
  (`lti.setup.linked_notice`), and the setup/trainings assignment-view strings;
  the `lumped` granularity radio label was removed with the deep-link-first change.
