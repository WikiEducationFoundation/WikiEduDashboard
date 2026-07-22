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
- [ ] **Data-sharing copy.** Update the data-sharing statements in
  `docs/canvas_integration_guide.md` and `docs/hecvat.md`: under anonymized mode
  Canvas shares only an **opaque user id + roster membership — no names or emails**.
  This is more accurate, and a stronger privacy statement than the current wording.
- [ ] **`auto_link_by_email` is now unused.** With anonymized mode there is no email,
  so `LtiMemberLinker#auto_link_by_email` never fires. Decide whether to remove it or
  keep it for any non-anonymized deployments.

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

- [ ] **Collapse the granularity model around deep-link-first.** `lumped` has
  been repurposed as the deep-link-first mode: it now auto-creates NOTHING
  (not even the setup/roll-up sentinels — those are importable via the picker,
  per operator direction 2026-07-21) and discovery binds any tagged column.
  The setup form still offers three radios with the `lumped` label as a
  placeholder; once deep-link-first is validated on staging, decide whether
  standard/per_block survive at all and redesign the setup step accordingly.

- [ ] **Bulk deep-linking via `module_index_menu_modal` (built; verified on
  staging except module naming).** The import flow works end-to-end. The
  created module's default name is Canvas's "New Content From App"; Canvas
  reads a tool-settable override from the deep-linking response JWT claim
  `https://canvas.instructure.com/lti/module_name` (found in
  `deep_linking_services.rb`), which we now send ("Research and write a
  Wikipedia article", operator-supplied) with a retry-without-it fallback in
  case LTIAAS rejects the extra field — pass-through unverified. Assignment
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

- [ ] **Auto-created assignments can't have descriptions (platform limitation).**
  Canvas shows "No additional details were added for this assignment." on every
  AGS-created column: the AGS line-item API accepts only
  label/scoreMaximum/resourceId/tag/resourceLinkId/start/end plus the
  `submission_type` extension — no description field (confirmed in Canvas's
  `lti/ims/line_items_controller.rb`). Deep-linked assignments DO support one
  (content-item `text` → assignment description), now sent by
  `BuildLtiDeepLinkForm` with placeholder copy
  (`lti.deep_link.assignment_description`) — verify LTIAAS passes `text`
  through on the next staging deep-link. For the auto-created columns the
  options are: live with Canvas's default text, have instructors hand-edit, or
  petition Canvas/LTIAAS for an extension. Copy for the deep-link description
  is needed before real courses use the picker (it's baked in at creation).

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

- [ ] **No UI to change gradebook layout after linking.** The setup form's
  granularity explanation promises "You can change this later," but nothing in
  the product lets an instructor change `gradebook_granularity` post-link. The
  new `instructor_status` launch view is the natural home. Needs design care:
  switching modes re-syncs the line-item set (columns get archived/created, never
  deleted from Canvas), so explain the consequences or constrain the switch.

## Deep-link picker (`DeepLinkableGradables`)

- [x] **Picker list isn't in timeline order.** _(Fixed on CanvasStaging.)_
  `gradable_blocks` now sorts by `week.order` then `block.order` in both
  `DeepLinkableGradables` (picker) and `SyncLtiLineItems` (auto-created columns —
  Canvas lists assignments in creation order, so creation must walk the
  timeline). Note: already-created Canvas assignments keep their positions; the
  order fix shows only for columns created after it deployed.
- [ ] **Picker offers the trainings roll-up even though it's auto-created.** `perform`
  unshifts the "Wikipedia trainings" roll-up whenever the course has trainings, but
  that column is already auto-created on sync (trainings stay auto-present in every
  granularity mode) — so picking it creates a duplicate. Drop the roll-up from the
  picker (not something an instructor should add manually), or hide it when already
  present. Naturally folds into the granularity redesign, since the code comment
  already notes `DeepLinkableGradables` and `SyncLtiLineItems` are slated to unify.

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
- [ ] **Deep-linked exercise shows the orphan view on first launch (no discovery
  sync after deep-linking).** Deep-linking an exercise (e.g. "Wk4 Bibliography",
  Block:530) creates the Canvas assignment correctly — resource marker in the launch
  URL + `custom_params` (`resource=Block:530`) and a gradebook line item (points 1.0).
  But opening it renders `assignment_view_orphan`, not the rich roster/sandbox panel.
  Root cause: `LtiDeepLinking#deep_link_select` does NOT schedule a line-item sync, so
  no local `LtiLineItem` row is created for the new column (line-item syncs only fire
  at link time, on `Block` edits via `perform_in(2.min)`, and from the wizard — none
  on deep-linking). With no local row, `ResolveAssignmentLineItem` can only bind from
  the launch's scoped AGS `lineItemId`, which Canvas doesn't reliably deliver (the code
  comments on this) → nil → orphan. Fixes: (a) schedule `LtiLineItemSyncWorker` after
  `deep_link_select` (like `Block` does) so the column is discovered + bound shortly
  after creation; and/or (b) make `ResolveAssignmentLineItem` discover the line item by
  tag via AGS (list line items, match `Block:<id>`) when it has the gradable but no
  local row and no launch `lineItemId` — mirroring
  `SyncLtiLineItems#discover_deep_linked_exercises`. Workaround to confirm: trigger a
  line-item sync for the binding, then re-open the assignment → rich view.

## Housekeeping (after the walkthrough)

- [ ] **Re-point the staging specs.** The old dev key + app were removed to reset for
  the walkthrough, so the existing `spec/staging/` specs and the screenshot harness
  (which reference the "wikiedu.org testing key" name / client id) are broken. Update
  them to the new registration once it's finalized.
- [ ] **Finalize guide + HECVAT placeholders.** Remaining `[PLACEHOLDER]`s: the
  manual-path config source, the support/activation contact, and the two
  troubleshooting specifics.
- [ ] **Fill the launch-view copy placeholders.** `grep '\[PLACEHOLDER' config/locales/en.yml`
  — the instructor status view's grade-sync error notice (header/explanation/
  sync-hint were resolved by the operator: "Wiki Education Dashboard" + ✓
  header, no explanation, refresh link instead of the hint), the post-link
  flash (`lti.setup.linked_notice`), the setup/trainings assignment views
  (summary, empty state, student strings), and the `lumped` granularity radio
  label + example.
