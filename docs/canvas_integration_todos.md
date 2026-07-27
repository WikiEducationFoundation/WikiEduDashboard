# Canvas integration — follow-ups

Deferred items from the Canvas / LTI integration work. None are blockers for the
current staging walkthrough; revisit as noted.

## Privacy / anonymized mode

Decision: **anonymized ("None (Anonymized)") is the main supported mode**, and
launch + Wikipedia OAuth is the only linking path.

- [x] **Roster legibility.** _(Explored + resolved 2026-07-24.)_ Only one surface
  ever printed a bare Canvas user id: `SetupAssignmentViewContext` (the trainings
  and per-block rosters list connected students only). Resolution: **the opaque
  ids are gone** — the "Wikipedia account" drill-down now lists connected students
  and carries the not-yet-connected as a count plus a callout pointing at the same
  column in the Canvas gradebook, where those students appear against Canvas's own
  names with no score. Copy is a `[PLACEHOLDER]` (`lti.assignment_view.setup.pending`).
  Re-harvest `03-setup-instructor-roster` after this deploys — the gallery shot
  still shows the old opaque-id row.
  - _Why not a click-through "who is this?" link:_ NRPS does hand us
    `lti11LegacyUserId` alongside the LTI 1.3 UUID, and Canvas resolves that via
    its `lti_user_id:` id prefix — but only where an instructor can't go. Verified
    against staging Canvas: `/api/v1/users/lti_user_id:<legacy>` and
    `/api/v1/courses/<id>/users/lti_user_id:<legacy>` → 200; `/users/lti_user_id:<legacy>`
    (web) → 200 but `users#show` requires `:read_full_profile`, which comes from an
    **account-level** `:read_roster` right, so admins only; and the course roster
    page `/courses/<id>/users/lti_user_id:<legacy>` → **404** (`context#roster_user`
    doesn't accept id prefixes). Still useful for Wiki Ed staff support: an account
    admin token can resolve an opaque id to a Canvas user.
  - _Also rejected:_ fetching NRPS live at render time to show LMS names when the
    platform provides them. Would work (see the privacy-level note below) but
    displays LMS names, which reads against the "opaque id + role only" wording in
    the guide and HECVAT.

- [x] **Staging's tool registration wasn't actually anonymized.** _(Fixed
  2026-07-24.)_ Discovered while exploring the above: the raw NRPS payload for a
  staging binding came back with `name`, `givenName`, `familyName`, `email`, and
  `picture` for every member. The developer key's `tool_configuration` did say
  `privacy_level: anonymous`, but the **installed** tool (account tool 5) was
  `public` — the installed tool is what governs launch claims and NRPS, and it
  had drifted from the key's config. Set to `anonymous` via
  `PUT /api/v1/accounts/1/external_tools/5`; re-dumped the payload and it now
  carries only `userId` / `lti11LegacyUserId` / `roles` / `status`. The Dashboard
  was already discarding the PII (`normalize_member`), so no behavior changed —
  but it was being sent. Now documented as an admin check in
  `docs/canvas_dev_setup.md` §0.
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
  - _Unblocked 2026-07-24:_ `default: disabled` used to be unsafe — in a course
    without the tab, students silently never enrolled and linking from the
    picker 500'd. Both are fixed (see **Nav-link-free, deep-link-first linking
    model** below), so the config change is now a config change only.
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

- [x] **Bulk deep-linking via `module_index_menu_modal` — done, module names
  included (2026-07-27).** The import creates one published module with all
  nine assignments in timeline order, now titled "Research and write a
  Wikipedia article". The full chain works: we send the claim → LTIAAS passes
  it into the signed JWT (their hotfix) → Canvas reads it (the upgrade below).
  History of the two blockers is kept because both were third-party fixes:

  Canvas takes the module's name from the deep-linking response JWT claim
  `https://canvas.instructure.com/lti/module_name` (read in
  `deep_linking_services.rb`), which we have always sent ("Research and write a
  Wikipedia article", operator-supplied), falling back to "New Content From
  App" without it. Two independent links in that chain were broken:
  LTIAAS dropped the claim — **confirmed 2026-07-24 by decoding the signed
  DeepLinkingResponse LTIAAS returned:** all nine content items present, no
  key containing "module" at all — and after we sent them that decode, LTIAAS
  confirmed they didn't pass the extra key through and shipped a hotfix.
  - **LTIAAS side: fixed and verified 2026-07-25.** They reported the hotfix
    deployed; `spec/staging/deep_link_module_name_diagnostic_spec.rb` (new)
    decodes the signed DeepLinkingResponse and finds the claim **present**, at
    both 2 and 9 content items, with `BuildLtiDeepLinkForm`'s
    retry-without-the-claim fallback never firing. Nothing left to do on our
    side or theirs.
  - **Canvas side: fixed by upgrading the box, 2026-07-27.** Canvas only
    *reads* the claim as of canvas-lms
    [8565b537](https://github.com/instructure/canvas-lms/commit/8565b53775aa)
    (2026-04-09, no feature flag); `canvas.wikiedu.org` was running
    `release/2026-02-11.378`, confirmed by grepping the deployed source for the
    reader (absent). Upgraded to `release/2026-05-20.143` (recipe + gotchas in
    `docs/canvas_dev_setup.md` → "Upgrading the test Canvas") and the very next
    import produced a correctly named module. Institutions on
    Instructure-hosted Canvas were never affected.
  - (Background: true server-side creation is
    impossible — a deep-linking response must POST through the instructor's
    browser to a launch-specific return URL — which is why the flow is
    one-click-bulk rather than automatic.) Remaining: add
    `module_index_menu_modal` to the LTIAAS config so future registrations
    carry it (the staging tool got it via a Canvas API edit only).

- [x] **Nav-link-free, deep-link-first linking model.** _(Explored 2026-07-24;
  decoupled rather than removed.)_ Outcome: the launch dispatch no longer
  depends on the course-navigation placement, so an institution can leave the
  tab off and drive everything from the deep-link / assignment launches — but
  the placement stays available (it's also the only home for the instructor
  sync-status view). Three defects were found in the process, all now fixed;
  each of them would have bitten the **`course_navigation` `default: disabled`**
  change above, independent of this exploration:
  - **Linking from a deep-link placement 500'd.** An `LtiDeepLinkingRequest`
    carries no `resourceLink` claim, and `LtiSession#lms_resource_link_id` read
    it unguarded → `NoMethodError` in `find_or_create_binding!`. The picker's
    own "not yet linked" landing sends the instructor through exactly that path
    (break out to `/lti/connect_course?ltik=…`, OAuth, back to `/lti?ltik=…`),
    so the only nav-free way to link a course was a 500. Verified locally with
    a synthetic deep-linking idtoken; never seen in staging logs because
    everyone links via the nav tab first. Fixed with a synthetic,
    context-stable `DEEP_LINKING_RESOURCE_LINK_ID` key.
  - **A student whose only launch is an assignment was never enrolled.**
    `launch` short-circuited to the drill-down before the student branch, so
    the launch rendered 200 and did nothing else: no `CoursesUsers` row, and
    their `LtiContext` linked to a throwaway per-assignment binding instead of
    the bound one — invisible to grade sync and to the setup roster, forever.
    Fixed by `LtiStudentEnrollment#ensure_launch_enrollment`, called from the
    assignment-launch branch (and rendering the pending-approval view when the
    course isn't approved yet, matching the nav launch).
  - **Per-assignment binding rows.** `find_or_create_binding!` keyed on
    (context, resource link), minting a row per assignment resource link —
    stranding contexts as above and letting the *bound* row's service
    credentials go stale, since only launches through its own resource link
    refreshed them. Now every launch from a linked Canvas course resolves to
    that course's bound binding. Staging still has 7 pre-existing unbound rows
    (harmless; they just hold credentials).
  - _Not done:_ dropping `lms_resource_link_id` from the binding's identity
    entirely (a binding models a Canvas course; the resource-link component is
    now vestigial). Needs a migration + unique-index change — worth doing if
    that table is touched again.
  - _Still open if the nav link is ever actually removed:_ `instructor_status`
    (sync status, "View in Canvas", the sync trigger) would need a new home,
    and first-time linking from the Modules picker is a two-pass flow (link in
    the new tab, return to Canvas, re-open the picker) because binding needs a
    Dashboard session the iframe can't have. A pure Dashboard-initiated "enter
    your Canvas course URL" flow remains blocked on the authorization gap: the
    launch is what proves the user teaches that course.

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

- [x] **Trainings/exercise rosters: N×M queries.** _(Batched 2026-07-24.)_ Both
  rosters were N students × M modules of `TrainingModulesUsers` lookups
  (LtiTrainingProgress / LtiBlockProgress per row). Now a constant number of
  queries: `TrainingsAssignmentViewContext#roster` uses one grouped
  completed-count query; `AssignmentViewContext#roster` preloads all students'
  TrainingModulesUsers for the block once and threads each slice into
  `LtiBlockProgress`'s new `completions:` param (with a memoized taken-claim set
  for the fact-verification "in progress" check).
  - _LMS-name identity: resolved 2026-07-24._ The anonymization removed
    `LtiContext#name`, so all three rosters now show the Wikipedia username (the
    setup roster still shows the CoursesUsers real name for connected students).

- [x] **Score-comment attribution shows "- Someone" (platform limitation).**
  _(Origin appended 2026-07-24.)_ Canvas creates AGS score comments with an
  authorless "- Someone" byline and no AGS field can set the author.
  `SyncLtiGrades#with_origin` now appends " — <dashboard host>"
  (`ENV['dashboard_url']`) to non-blank comments, so the note says where the
  score came from. Canvas still renders its own "- Someone" line beneath — that
  part is unfixable via AGS.

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
  `gradable_type`: SETUP renders an account-connection roster (connected students
  listed; not-yet-connected carried as a count — see **Roster legibility**) via
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
- [~] **Fill the launch-view copy placeholders.** _(Done once; one new
  placeholder since.)_ `lti.assignment_view.setup.pending` — the
  not-yet-connected callout added by the roster-legibility change (2026-07-24) —
  is the only `[PLACEHOLDER]` left in `config/locales/en.yml`. The operator filled the grade-sync
  started/error notices, the import next-step, the post-link flash
  (`lti.setup.linked_notice`), and the setup/trainings assignment-view strings;
  the `lumped` granularity radio label was removed with the deep-link-first change.
