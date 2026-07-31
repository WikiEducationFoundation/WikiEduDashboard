# Canvas integration — follow-ups

Deferred items from the Canvas / LTI integration work. Revisit as noted.

## Where things stand (2026-07-30)

Branch state, so a fresh session doesn't have to reconstruct it:

- **PR #6934**, branch `CanvasStaging`. `staging` tracks it and is what
  `cap staging deploy` ships — see the deploy notes in that memory, especially
  checking out `CanvasStaging` again afterwards.
- **Seven review rounds** have been answered (gpt-5.6-sol ×3, Claude Code ×3
  including a verification pass, Codex/GPT-5 ×1) — see the dated follow-up
  sections below for the 2026-07-30 rounds. Replies are posted as PR comments.
- **Screenshot gallery**: `pr-screenshots/CanvasStaging-gallery-20260730`, 38 shots
  across 8 flows, posted as a PR comment. Regenerate the comment with
  `bin/harvest-canvas-screenshots --pr-comment=<raw base url>` rather than by hand.
- **Staging** is deployed and its LTI schema verified against the branch. Note that
  deploys do **not** apply this work's migrations — schema changes go on by hand over
  SSH. See the `lti_contexts` collation item below for the one known difference.
  - **Three columns added 2026-07-30 were applied to staging by hand the same
    day** (they were folded into the unshipped migrations, whose versions
    staging already recorded, so a deploy would never have added them).
    Verified by `SHOW COLUMNS` after applying; the columns sit unused until the
    next deploy ships the code that reads them. For the record:

    ```sql
    ALTER TABLE lti_course_bindings
      ADD COLUMN last_roster_sync_error TEXT AFTER last_roster_sync_at,
      ADD COLUMN last_grade_sync_attempt_at DATETIME(6) AFTER last_grade_sync_error;
    ALTER TABLE lti_contexts
      ADD COLUMN lms_membership_status VARCHAR(255) AFTER linked_at;
    ```

    A fourth change followed the same day, from the fourth review's deep-link
    fix (also applied to staging by hand, verified nullable):

    ```sql
    ALTER TABLE lti_line_items MODIFY lineitem_id VARCHAR(512) NULL;
    ```

### Which open items a real user can actually hit

_(2026-07-30: all three user-reachable priorities below were addressed in a
parallel-agent pass — links fixed, pre-activation documented and decided, and
the whole UI/UX list fixed, with all new copy since filled by the operator. Of
the hygiene items, the roster-sync error field, periodic-sync starvation, and
harness relocation are also done, and the staging ALTERs above are applied.
Every operator decision was settled in the same day's walkthrough; the only
open items left in this file are the two deliberate deferrals, encryption and
collation.)_

Most of the list is internal or operator-facing. These are the ones reachable by an
instructor or student in an ordinary course, and so the ones worth doing first:

1. **Links in rendered timeline content** (below) — a link in *shipped wizard
   content* blanks the Canvas iframe with no in-frame recovery, and the wizard
   timeline is now what every gallery and every real course uses.
2. **Pre-activation launch shows raw JSON** (below) — hit by an instructor who
   launches before Wiki Education activates the LTIAAS registration, which is the
   normal sequence for a new institution rather than an edge case.
3. **Several of the UI/UX items** (below), particularly the first-time instructor
   with no Dashboard course landing on the "awaiting approval" message with no way
   forward, and an expired ltik 500ing behind the default `X-Frame-Options` so the
   frame reads as a blank "refused to connect".

## Privacy / anonymized mode

Decision: **anonymized ("None (Anonymized)") is the main supported mode**, and
launch + Wikipedia OAuth is the only linking path.

- [x] **Roster legibility.** _(Explored + resolved 2026-07-24.)_ Only one surface
  ever printed a bare Canvas user id: `SetupAssignmentViewContext` (the trainings
  and per-block rosters list connected students only). Resolution: **the opaque
  ids are gone** — the "Wikipedia account" drill-down now lists connected students
  and carries the not-yet-connected as a count plus a callout pointing at the same
  column in the Canvas gradebook, where those students appear against Canvas's own
  names with no score. Operator copy for the callout
  (`lti.assignment_view.setup.pending`) landed 2026-07-27; note it states the
  count without repeating the gradebook pointer.
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
  and `lti_contexts.name`/`.email` are gone. _(Originally added then dropped by
  a later migration; since neither had shipped, the pair was consolidated
  2026-07-28 so the columns are never created at all — see "Follow-ups from the
  code review" below.)_

## Admin registration UX

> **Walkthrough 2026-07-27.** The registration was deleted and redone from
> scratch by a root-account-only admin (no Site Admin) following the live guide,
> to see what an institution actually gets. Findings are folded into the items
> below; the four that matter:
> 1. **Registering is not installing, and installing is not availability.**
>    Dynamic registration creates the developer key and an install that Canvas
>    already marks "Installed in <account>" — but with availability **Not
>    Available**, which means no `ContextExternalTool` exists and *nothing*
>    appears in any course. The fix is Developer Keys → the row's **Details**
>    column → **View in Canvas Apps** → Edit the installation → **Not Available
>    → Available**. The guide's step 3 ("+ App → By Client ID") describes a
>    different, unnecessary path, and following the guide as written twice
>    produced a silently invisible tool.
>    - _Alternative worth documenting:_ leaving it Not Available and using
>      **Add Exception** per course. That is admin-controlled per-course
>      enablement of the whole tool — arguably a better fit for Wiki Ed than
>      `course_navigation default: disabled` (which only hides the tab and
>      leaves the instructor to find it).
> 2. **The admin's "Anonymized" choice does not reach the installed tool.**
>    Selected during registration, it is stored as `overlay.privacy_level:
>    anonymous`, yet the tool installs as `privacy_level: public`. Reproduced
>    twice (tool 5 in February, tool 9 on 2026-07-27). So an institution that
>    does the right thing still sends us names and emails. Report to
>    Instructure, and treat the LTIAAS-side fix as the real remedy.
>    - **Resolved 2026-07-29: set the level as a query parameter on the
>      registration URL** —
>      `https://<tenant>.ltiaas.com/lti/register?privacyLevel=anonymous`. That takes
>      the decision out of the dialog Canvas drops, so the guide no longer asks the
>      admin about it at all. **Verified against Canvas** by
>      `staging_specs/privacy_level_registration_spec.rb`, which registers a fresh app
>      with the parameter, deploys it, and asserts `anonymous` on both the developer
>      key's `tool_configuration` and the installed tool — the latter being the half
>      that governs launch claims and NRPS, and the half the dialog never reached.
>      - Note the camelCase. LTIAAS's first answer gave it as `privacy_level`, which
>        Canvas forwards and LTIAAS ignores, so the registration comes out at the
>        tenant default (`public`) — a result indistinguishable from `anonymous`
>        being unsupported. That cost a round trip and a wrong guide; the docs were
>        published with the wrong spelling before the spec existed to catch it.
> 3. ~~**`module_index_menu_modal` is absent**, as expected — the Modules bulk
>    import does not exist on a fresh registration.~~ **Not reproduced, and this
>    note was wrong.** Sage's later walkthrough had the Modules import working,
>    and checking the installed tool from that same 2026-07-27 registration
>    confirms it (`GET /api/v1/accounts/1/external_tools/10` on 2026-07-29 lists
>    `course_navigation`, `assignment_view`, and `module_index_menu_modal`). A
>    registration against the current LTIAAS config gets all three placements, so
>    the guide's description of the Modules import is accurate.
> 4. **Every placement is labelled with the tool name** ("wikiedu.org
>    testing"), confirming the Title fallback below.

- [x] **Placement Title / Icon URL.** _(Closed 2026-07-30: the guide's
  Installation step 1 now carries operator-approved wording — leave Title/Icon
  blank, placements take the tool's name "Wiki Education Dashboard" and logo.
  That promise makes the production tenant's Tool Name the load-bearing setting;
  a check for it is now first in `docs/canvas_dev_setup.md`'s production rollout
  checklist. Per-placement titles are a possible LTIAAS feature request, not
  filed.)_ Original item: the dynamic-registration "Register App" dialog
  shows empty **Title** and **Icon URL** fields per placement, and a blank Title
  falls back to the tool's internal name (e.g. "wikiedu.org testing"). LTIAAS does
  **not** appear to expose per-placement titles/icons (only the overall tool logo),
  so the admin has to set the Title during registration. Therefore: (a) the guide
  must document the Title field and recommend a value ("Wiki Education Dashboard"),
  and (b) double-check whether LTIAAS supports per-placement `text`/`icon_url` via
  some other config path.
  - _(b) answered definitively, 2026-07-30:_ **No.** Confirmed three ways — the
    LTIAAS portal exposes only tool-wide Name/Logo; the Complete Registration
    API's `messages` schema is `{type, placements}` and nothing else (verified in
    LTIAAS's own Node SDK, whose zod schema can't even represent extra keys); and
    the upstream ltijs source builds registration messages bare, with only
    top-level `client_name`/`logo_uri`. Canvas's dynamic-registration endpoint
    *does* read per-message `label`/`icon_uri` (and extensions like
    `default_enabled`) — LTIAAS simply never sends them, so the blank Title
    falling back to the tool name is expected behavior, not a config miss. The
    levers: keep the account-wide Tool Name presentable, have the admin type the
    Title during registration, or file a feature request (no public support
    email; ltiaas.com/contact-us or portal.ltiaas.com). Remaining here: (a) only —
    guide wording, which is the operator's.

- [x] **LTIAAS config: add `course_navigation`, `default: disabled`.** _(Decided
  against for beta, 2026-07-29: the nav item appearing in every course is good
  enough for beta testing, so the config keeps its `enabled` default and the docs
  were made consistent with that by omission — the guide no longer offers the
  opt-in choice, no longer says the item is hidden by default, and no longer has
  the instructor enable the tab. `docs/canvas_dev_setup.md` §6 records which value
  ships and why.)_ Original item, for when this is revisited: dynamic
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
- [x] **Guide: install shortcut + optional titles.** _(Closed 2026-07-30 —
  mostly already done.)_ The guide's Installation section had already gained the
  "View in Canvas Apps" route (steps 3–4) in the operator's earlier rewrite; the
  optional-titles note landed with the Placement Title item above. Original
  item: point the guide at the "View in Canvas Apps" link as the easy route to
  install/manage the app, and note the placement Title/Icon fields are optional.

## Linking / launch model (design)

- [x] **Deep-link-first is now the model (decided + shipped 2026-07-23).** Per
  operator direction, the gradebook-layout radios were removed from the setup
  step entirely — linking a course just links it. New bindings default to
  `lumped` (auto-create nothing); the instructor imports every column (account
  indicator, trainings roll-up, exercises) via the Modules "Import Wikipedia
  assignments" flow, and `SyncLtiLineItems` discovers + binds them.
  - **`standard`/`per_block` removed.** _(Done 2026-07-29, from the second code
    review.)_ Both auto-creating layouts and the `gradebook_granularity` column
    are gone; deep-link-first is the only layout. That also removed the
    auto-create and label-push branches in `SyncLtiLineItems`, the
    `exercises_only:` flag on `LtiBlockProgress` (every caller wanted it), and
    the unused `update_line_item` / `delete_line_item` AGS verbs plus the
    `LtiaasClient` PUT/DELETE they relied on. The two screenshot galleries that
    forced `standard` now seed the same columns the Modules import produces
    (`DashboardAdminClient.import_all_columns`), so they exercise the shipped
    discovery path.

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
    deployed; `staging_specs/deep_link_module_name_diagnostic_spec.rb` (new)
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
    that course's bound binding. (Staging had 7 pre-existing unbound rows at the
    time; a probe on 2026-07-28 found just the one bound row left, so they were
    cleaned up somewhere along the way.)
  - **`lms_resource_link_id` dropped from the binding's identity.** _(Done
    2026-07-28, from the code review.)_ The unique index still included it while
    `bound_binding` resolved by context alone, so two pre-link launches from
    different resource links in one Canvas course could mint two rows competing
    to be the bound one, and the lookup was nondeterministic if both got linked.
    Identity is now `(lms_id, lms_context_id)` for both the index and the
    lookup; the column stays as a snapshot of the most recent launch.
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

- [x] **Rejected / pre-activation launch shows raw JSON.** Launching before LTIAAS
  activates the registration (or any LTIAAS-rejected launch) surfaces a raw JSON
  error in the Canvas iframe — LTIAAS returns it before the launch reaches our app,
  so we can't render a friendly page. Manageable since Wiki Education controls
  activation timing, but: document "activate before instructors launch," and check
  whether LTIAAS can present a friendlier pre-activation message.
  - _Researched + documented 2026-07-30; what's left is an operator decision._
    LTIAAS has **no custom error page** — the raw JSON
    (`UNREGISTERED_OR_INACTIVE_PLATFORM`) is its documented behavior. But two
    documented mechanisms close the window entirely: the portal's **Dynamic
    Registration Auto-Activation** toggle (registrations activate on creation —
    also removes the chance to vet who registers), and the **Pre-Approval flow**
    (registering admin's iframe redirects to a Wiki Ed URL with
    `?registrationId=`; approve via `POST /api/registrations/{id}/complete` with
    `autoActivate: true` — keeps the vetting gate, doubles as real-time
    pending-registration notification, costs a small endpoint). The
    "activate before instructors launch" guidance plus both options are now in
    `docs/canvas_dev_setup.md` → "Production rollout checklist".
  - _Decided 2026-07-30:_ **manual, prompt activation.** Keeps the vetting gate
    at zero build cost, which fits the beta posture of hand-picked institutions;
    the raw-JSON window is managed by process (activate promptly, tell the
    institution not to point instructors at the tool until confirmed). Revisit
    the pre-approval endpoint if self-service registration ever scales.

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
  only the column default changed, and the two default flips were later folded
  into the create migration when the deep-link-first change made `lumped` the
  default again). Setup radios render from
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
- [x] **Finalize guide placeholders.** _(Done 2026-07-27.)_ `docs/hecvat.md` was
  already clean and the dev guide's guide/HECVAT links were filled. The operator
  then resolved the rest of `docs/canvas_integration_guide.md`: the data-sharing
  summary now stands on its own wording, and both troubleshooting placeholders
  were dropped rather than written — "refused to connect" because none of its
  triggers can reach an institution's admin (it's a symptom of a Dashboard-side
  error, so the diagnostic detail moved to `docs/canvas_dev_setup.md`), and sync
  timing because the in-Canvas panel now carries a Sync grades trigger. The
  draft banner no longer advertises placeholders.
- [x] **Fill the launch-view copy placeholders.** _(Done — `grep '\[PLACEHOLDER'`
  across `config/locales/en.yml`, `app/`, and `docs/` now returns nothing.)_ The
  last one was `lti.assignment_view.setup.pending`, the not-yet-connected
  callout from the roster-legibility change, filled 2026-07-27. Earlier, the operator filled the grade-sync
  started/error notices, the import next-step, the post-link flash
  (`lti.setup.linked_notice`), and the setup/trainings assignment-view strings;
  the `lumped` granularity radio label was removed with the deep-link-first change.

## Follow-ups from the gpt-5.6-sol code review (2026-07-28)

Items from that review that were assessed as real but deliberately left out of
this PR. The review's other findings were fixed on the branch.

> **Migrations were consolidated (2026-07-28), on the review's recommendation.**
> None of the LTI migrations had run on either production server, so the
> add-then-remove pairs and the two `gradebook_granularity` default flips are
> gone: `lti_contexts.name`/`.email` and `lti_line_items.last_pushed_signature`
> are never created, `lms_context_title` / `lms_platform_url` /
> `canvas_assignment_id` are created with their tables, and both index changes
> from this review are folded in. Four migrations remain
> (`2026050513320{0,1,2}`, `20260511105551`).
>
> **The staging database needed two index changes**, since it had already
> recorded the superseded migration versions and so would never run the folded-in
> ones. Probed 2026-07-28: everything else already matched (the PII columns were
> already dropped, `canvas_assignment_id` / `lms_context_title` /
> `lms_platform_url` present, `last_pushed_signature` gone,
> `gradebook_granularity` defaulting to `lumped`), and there were no rows
> violating either new index — 1 binding, 10 contexts, no duplicates. So a full
> reset wasn't needed; the two indexes were applied by hand and are recorded
> below. Note staging's `schema_migrations` still holds the five superseded
> version rows, which is harmless — no file matches them, so nothing re-runs.

- [ ] **Encrypt long-lived external credentials — a pre-production dependency,
  and app-wide rather than just here.** `lti_course_bindings.ltiaas_service_credentials`
  is plain text. So are `users.wiki_token` / `users.wiki_secret`, the Wikipedia
  OAuth credentials for every account on the site. This app has no Active Record
  encryption anywhere, so encrypting one new column means standing up
  `active_record_encryption` key management on both production deployments (Wiki
  Ed and Peony) plus dev and CI, for one column, while the larger and more
  numerous credential store stays in the clear — which is why it isn't in this PR.
  It is not a reason to treat the new credential as fine, though, so recording
  what has to be true before this ships to real institutions:
  - _Reviewed with the operator 2026-07-30: **stays fully deferred**, gated on
    real institutions._ Encrypting just the new column pre-ship (zero backfill;
    production would never hold a plaintext service key) was considered and
    declined; the rotation and incident-response decisions below stay bundled
    here rather than being settled early. One finding from that review worth
    keeping: **both credential families are half-credentials.** The service key
    is only usable together with the ENV-held `LTIAAS_API_KEY`, and
    `wiki_token`/`wiki_secret` only together with the ENV-held OAuth consumer
    secret — so a database-only leak (dump, backup, injection read) does not by
    itself grant API access to either external system. That makes this item
    defense-in-depth plus institutional-review posture (the HECVAT's DATA-03
    already answers an honest "No" on at-rest encryption) rather than a direct
    exposure.
  - **Blast radius, written down.** An `ltiaas_service_credentials` value grants
    NRPS (roster read) and AGS (gradebook read/write) on that one Canvas course,
    via LTIAAS, until rotated. It does not grant anything else in Canvas, and it's
    per-binding rather than tenant-wide.
  - **Rotation.** Each launch refreshes the stored key from the launch idtoken
    (`LtiSession#find_or_create_binding!`), so a course that's actively used
    rotates on its own; there is no operator-driven rotation path, and no way to
    revoke one binding's key without LTIAAS. Decide whether that's sufficient and
    document it.
  - **Incident response.** Decide the procedure for a suspected database
    disclosure: at minimum, what to null out (`UPDATE lti_course_bindings SET
    ltiaas_service_credentials = NULL` stops all background NRPS/AGS calls
    immediately and is safe — the next launch re-populates it), who at LTIAAS to
    contact, and what to tell affected institutions.
- [x] **Remove the `standard` / `per_block` gradebook granularities.** _(Done
  2026-07-29 — see "Linking / launch model" above for what came out with them.)_
- [x] **Move the live-Canvas harness out of `spec/`.** _(Done 2026-07-30.)_
  `git mv spec/staging staging_specs` — 30 files, all tracked as renames;
  `bin/staging-feature-spec` and `bin/harvest-canvas-screenshots` re-pointed, and
  the `.rubocop.yml` excludes that used to reach these files via `spec/**/*`
  carried over. The `:staging` tag machinery moved from `spec/spec_helper.rb`
  into `staging_specs/spec_helper.rb`, which closed a pre-existing hole: the
  auto-tagging derived-metadata rule used to live in a spec_helper the staging
  path never loaded, so an untagged staging file run directly would have executed
  live — now the rule sits in the helper those specs actually require, and
  `bundle exec rspec staging_specs/...` without `--tag staging` runs 0 examples.
  There was no `.rspec` file to update (the original item guessed wrong). Default
  suite dry-run after the move: 3330 examples, zero loaded from the harness.
  Original item, for the record: RSpec used to *load* the staging files — and
  with them the Selenium helpers — on every normal suite run.
- [x] **Persist NRPS membership status.** _(Stored + surfaced 2026-07-30.
  Disenrollment policy decided the same day: **flag only, nothing automatic** —
  removal in Canvas doesn't always mean removal from the Wikipedia assignment,
  so staff act on the flag manually. "Flag + staff notification" was considered
  and can be revisited if flags go unnoticed in practice.)_ `lti_contexts.lms_membership_status` (folded into
  `20260505133202`; staging ALTER recorded under "Where things stand") is written
  in `LtiMemberLinker#apply_member_attributes`, so every member — new, deferred,
  or already linked — carries the current NRPS status after each roster sync.
  `LtiContext#removed_from_lms?` (nil = never synced = not removed) drives a
  flag pill next to "Connected" in the setup roster
  (`lti.assignment_view.status.removed_in_lms`, label filled by the operator
  2026-07-30).
  Original item: `normalize_member` read Canvas's Active/Inactive/Deleted status
  and the linker used it transiently, but nothing stored it, so there was no
  staff-visible "was removed in Canvas" state to reconcile against.

## Operator copy still to confirm (second review, 2026-07-29)

Two documentation statements the second review flagged that are the operator's to
word, not Claude's. Neither was rewritten; both are recorded here instead.

- [x] **The guide's three contradictions are all closed.** _(2026-07-29.)_ Of the
  three the review found:
  - **Nav item "hidden by default"** — resolved by deciding not to make it
    default-disabled, and removing the claim (see "Admin registration UX" above).
  - **Modules import absent from a fresh registration** — was never true; our own
    walkthrough note was wrong, and the installed tool has the placement.
  - **"Anonymized" meaning Canvas doesn't transmit names** — resolved, and
    verified. `?privacyLevel=anonymous` on the registration URL yields `anonymous`
    on both the developer key and the installed tool
    (`staging_specs/privacy_level_registration_spec.rb`, green 2026-07-29). The
    guide's data-sharing paragraph is now accurate for a new registration.
    - **Staging's own tool stays `public`** — decided 2026-07-29, not an oversight.
      Tool 10 predates the parameter, so staging transmits names and emails that
      `LtiServiceSession#normalize_member` discards on receipt. Left as-is because no
      real users or data are on staging, and re-registering would cost the developer
      key, its AGS line items, the demo course's bindings, and a gallery rebuild. Two
      consequences to keep in mind: the admin gallery's data-sharing screenshot shows
      `public` rather than the `Anonymized` a new institution will get, and anyone
      verifying the privacy posture on staging is verifying the wrong tool — use
      `staging_specs/privacy_level_registration_spec.rb`, which registers its own.
- [x] **`docs/canvas_integration_guide.md`: "already signed in".** _(Fixed
  2026-07-29, with Sage's go-ahead on guide wording.)_ Also fixed in the same pass:
  the troubleshooting entry that still told admins the instructor must enable the
  nav item per course. Original note: The
  course-navigation bullet says instructors and students open the Dashboard from
  the nav link "already signed in." That isn't what happens. Inside the Canvas
  iframe, cookies are partitioned away from the top-level Dashboard session, so
  there is usually no session at all; the launch renders read-only views from the
  ltik alone, and anyone who hasn't yet connected a Wikipedia account has to
  break out to a new tab and complete OAuth first. Accurate copy needs to say
  something closer to "open the Dashboard from a link in the course's left-hand
  navigation — the first time, students connect their Wikipedia account in a new
  tab; after that the tool shows their progress in place."
- [x] **HECVAT REQU-08 understates what a binding stores.** _(Fixed 2026-07-30
  with operator-approved wording: a sentence appended to the REQU-08 note
  describing the course-level configuration record — course ID and name, Canvas
  URL, service endpoints and per-course credential — as institutional
  configuration data rather than student data. The per-student sentence is
  untouched.)_ Original item: it said the Dashboard
  "stores only the link between the Canvas ID and the Dashboard account". A
  `LtiCourseBinding` also persists `lms_context_title` (the Canvas course name),
  `lms_context_id`, `lms_platform_url`, `lms_resource_link_id`, `nrps_url`,
  `ags_lineitems_url`, and the service credential. None of it is student personal
  data, and the guide's version of the same claim (its "What data is shared" bullet)
  is correctly scoped — but the HECVAT's sentence is narrower than the truth. From
  the third review; relayed at the time but not written down until now.
- [x] **Check the DPAI-02 wording I volunteered.** _(Confirmed by the operator
  2026-07-30 — the disclosure stays as written; the alternative of flipping
  `public_dashboard_link` to make reports access-controlled was considered and
  not taken.)_ Original item: its note now discloses that a
  Pangram submission produces a report hosted at a URL that is not access-controlled,
  its content being the public Wikipedia text submitted — from
  `public_dashboard_link: true` in `lib/pangram_api.rb:14`. True, and a reviewer would
  want it, but it is the one place in the AI tab where Claude Code added a disclosure
  rather than reworded an existing answer, so it deserves an operator read.
- [x] **"Anonymous" vs "Anonymized".** _(Decided 2026-07-30: **"Anonymized"**,
  the Canvas admin-UI label, in prose in both documents — a one-word change to
  the HECVAT's REQU-08, since the guide already used it. Literal API values
  (`privacyLevel=anonymous`) are untouched.)_ Original item: the two documents
  disagreed — `anonymous` is the API/`privacy_level` value, "None (Anonymized)"
  is the label in Canvas's admin UI — and the UI label is what an institution's
  admin will recognize.
- [x] **`docs/hecvat.md` PDAT-03.** _(Resolved 2026-07-29: Sage accepted the
  drafted wording, so the `[DRAFT]` marker is removed.)_

## Third-review follow-ups (2026-07-29)

The mechanical findings and the two design ones are fixed on the branch. What's
left, in the order it seems worth doing:

- [x] **Lateness signalling was removed, not fixed.** _(Decided 2026-07-30:
  **not for the beta — revisit on instructor demand.** The Dashboard shows
  completion state itself, and the correct version requires per-course
  completion timestamps in core training data, so it isn't built until someone
  actually wants it.)_ Original item, kept because it documents why the naive
  version can't come back: `LtiBlockProgress` no longer
  emits a `[Late]` gradebook comment. The old one was computed from "score at
  maximum and the due date has passed" with no completion time consulted, so every
  student who finished on time picked up the marker as soon as the due date went
  by — and the class comment invited instructors to act on it. Re-introducing it
  needs a per-course completion timestamp for exercises first:
  `TrainingModulesUsers#mark_completion` writes
  `flags[course_id] = { marked_complete: value }` and records no time, and the
  flags column is shared with the non-LTI course views, so this is a change to
  core training data rather than to the integration. Worth deciding whether Wiki
  Ed wants lateness in the gradebook at all before building it.
- [x] **`SyncLtiRoster` has no error field to surface.** _(Fixed 2026-07-30.)_
  `lti_course_bindings.last_roster_sync_error` (folded into `20260505133200`;
  staging ALTER recorded under "Where things stand"), written and cleared by the
  service in the exact shape of the grade pattern: any whole-run failure records
  `"Class: message"` (truncated to the same limit) and re-raises for Sidekiq; a
  completed run clears it in the same `update!` as `last_roster_sync_at`;
  per-member skips stay Sentry-only. Surfaced via
  `LtiSyncStatus#roster_sync_error?`, the JSON payload, the course-page sidebar
  (`staff_view.jsx`), and the in-Canvas instructor view — two `[PLACEHOLDER]`
  strings pending (`lms_integration.last_roster_sync_error`,
  `lti.status.roster_sync_error`). Original problem: a roster sync that
  dead-lettered was invisible in both surfaces while `last_roster_sync_at`
  simply stopped advancing.
- [x] **`LtiPeriodicGradeSyncWorker` can be starved by a broken binding.**
  _(Fixed 2026-07-30, via the attempt timestamp.)_ The dispatcher stamps
  `lti_course_bindings.last_grade_sync_attempt_at` (same folded migration) as it
  enqueues each binding and orders on that, never-attempted first; the
  50-per-cycle cap is unchanged. A binding that always aborts now rotates to the
  back after each attempt instead of holding a front slot with its stale
  completion timestamp. Original problem: `last_grade_sync_at` only advanced on
  a completed sync, so a persistently failing binding sorted first every cycle
  and enough of them would stop healthy bindings from being graded.
- [x] **Links in rendered timeline content navigate the Canvas iframe away.**
  _(Fixed 2026-07-30.)_ New `RewriteLtiContentLinks` service, applied through an
  `lti_iframe_content` helper (sanitize first, post-process second): every
  anchor gets `target="_blank"` + `rel="noopener"`, and relative/root-relative
  hrefs are absolutized against `ENV['dashboard_url']`; fragment-only and
  href-less anchors untouched. Applied at `assignment_view`'s block-content
  render — audited the other lti_launch views and none renders raw user/wizard
  HTML (the deep-link auto-submit form is app-generated and deliberately
  skipped; the `link_to`-built partials already carry target/rel). Original
  problem: Rails' sanitizer strips `target`, so a link in shipped wizard content
  navigated the iframe away, and Dashboard-relative links blanked it behind
  `X-Frame-Options` with no in-frame recovery.
- [ ] **`lti_contexts` still migrates with the wrong collation.** Its `create_table`
  shipped in Feb 2025 without the `utf8mb4_unicode_ci` pin the other LTI tables
  now carry, so a forward `db:migrate` on modern MariaDB gives it
  `utf8mb4_uca1400_ai_ci` — which is what re-dumps a `schema.rb` that then breaks
  `db:schema:load` on MySQL. Fixing it means a `CONVERT TO` migration on a table
  with production rows, so it isn't part of this PR.
- [x] **UI/UX list from the third review.** _(All nine actionable items fixed
  2026-07-30; the tenth — the pending-count callout naming no next step — was
  left alone because the operator chose that copy deliberately on 2026-07-27.)_
  What landed, with new copy as `[PLACEHOLDER]`s throughout (keys listed in the
  "Fill the 2026-07-30 copy placeholders" item below):
  - Setup now distinguishes zero-Dashboard-courses (create-a-course path) from
    courses-awaiting-approval, so the first-time instructor has a way forward.
  - `LtiaasClient` errors are rescued to a friendly in-frame error view (502,
    framing explicitly allowed since `rescue_from` skips the `after_action`),
    and the framed actions that used to `redirect_to errors_login_error_path` —
    including "Sync grades" on a stale tab, the most reachable case — render
    in-frame when the request comes from an iframe (`Sec-Fetch-Dest`) and keep
    the redirect top-level otherwise.
  - `complete_setup` no longer shows instructors the student-audience
    enrollment error; a new `DuplicateUserLinkError` distinguishes the
    self-service case (identity already linked to a different account) from
    other link conflicts, each with its own message (409).
  - `sign_in_to_continue` gained the same check-again re-launch link as the
    other landings (existing string reused; it was the one landing without
    one and the one guaranteed to be stale).
  - `student_status` shows an empty state instead of a bare header when the
    course has no timeline yet.
  - The deep-link picker's bare `head :forbidden` (blank page in the Canvas
    modal) is now a friendly 403 view. **Role policy untouched — and the
    review's TA claim looks wrong:** Canvas sends base `membership#Instructor`
    for TAEnrollment too, so TAs likely already counted as instructors; the
    blank-page audience was observers/designers/unknown roles. _Decided
    2026-07-30: TAs acting as instructors (linking, importing, rosters) is the
    intended policy, not an accident — no role-mapping change._
  - The course-page sidebar now renders the actual grade/roster error strings
    and timestamps instead of a bare "Last sync error" field name.
  - The sandbox preview marks itself loaded only on success (failures are
    retryable by re-toggling), and its three hardcoded English strings moved
    verbatim into `en.yml`.
  - Every LTI page has exactly one `<h1>` and no heading-level gaps
    (`sign_in_to_continue` and `assignment_view_orphan` got headings from their
    existing title strings); `_lti_iframe.styl` adjusted so nothing changes
    visually, `yarn build` run and the compiled CSS verified.

## Fourth-review follow-ups (2026-07-30, gpt-5.6-sol)

All four findings were assessed against the code with Sage the same day; three
produced fixes on the branch, one produced a recorded policy decision.

- [x] **Canvas role revocation does not revoke Dashboard instructor access.**
  _(Facts confirmed; decided: leave as is.)_ `LtiMemberLinker` promotes and
  never demotes, so a former Canvas instructor keeps Dashboard edit rights
  until revoked manually, and the removal flag surfaces only in the
  learners-only setup roster. Kept deliberately: Dashboard instructor roles
  carry no provenance (nothing records whether the linker or an ordinary
  Dashboard flow granted one), and the course creator may not be on the Canvas
  roster at all, so demoting on NRPS could strip the course owner's own
  access. Provenance-tracked demotion and a staff-visible flag were considered
  and not taken. The class comment's TA rationale was corrected — Canvas sends
  the base Instructor role for TAEnrollments, so the old "TAs don't map"
  argument was wrong.
- [x] **Deep-link double-submit could create duplicate Canvas assignments.**
  _(Fixed.)_ `deep_link_select` now takes a transactional pending reservation
  per chosen gradable (new `ReserveLtiLineItems`; `lti_line_items.lineitem_id`
  made nullable in the unshipped create migration; staging ALTER recorded and
  applied — see "Where things stand"). The `(binding, gradable_key)` unique
  index makes the loser of a race 422 instead of minting a second Canvas
  column. Discovery (`SyncLtiLineItems`) and launch resolution
  (`ResolveAssignmentLineItem`) adopt pending rows; abandoned reservations are
  destroyed after 30 minutes (`PENDING_EXPIRY` — no Canvas column ever existed
  behind them); archived rows are revived by compare-and-swap so a re-import
  after column deletion still works. Every `lti_line_items` consumer was
  audited: grade sync and `assignments_imported?` are now bound-only, the
  picker's taken-set deliberately counts reservations.
- [x] **Grade-sync per-student tier swallowed application errors.** _(Fixed
  as the review suggested.)_ `push_one` no longer rescues bare StandardError:
  only an AGS rejection (`LtiaasClientError`) is per-student; compute or
  persistence failures abort the run, record the error, and reach Sidekiq's
  retry. Accepted trade-off: one student's corrupted data now blocks that
  binding's sync loudly instead of failing quietly per-student forever.
- [x] **`lms_membership_status` was missing from the privacy surfaces.**
  _(Fixed; field kept per the flag-only decision.)_ The personal-data CSV
  exports "Membership Status (from LMS)", and the guide's data-sharing bullet,
  HECVAT REQU-08, and PDAT-03 all state the enrollment status with
  operator-approved wording (2026-07-30).

## Claude third-round review follow-ups (2026-07-30)

The fifth review overall (a Claude Code session's fix-verification + delta
pass at `d43b6fe38`). Nothing blocking; everything addressed or decided the
same day.

- [x] **One wording correction accepted.** The reply to the `a1beefd9` reviews
  overstated "the dormant modes' wizard hook" as removed. It wasn't — and it
  shouldn't be: with `SyncLtiLineItems` now discovery/archival-only, the
  wizard/Block hooks are what keep line items tracking timeline edits. The
  auto-creation risk the original finding described is gone regardless.
- [x] **Stale comments and docs fixed.** `config/schedule.yml` (membership
  status now stored + surfaced), the `?privacy_level=` misspelling in the
  registration spec's opening comment and `.env.staging-tests.example`, the
  lateness-marker comments in `LtiServiceSession`/`SyncLtiGrades`, the
  `per_block`/`lumped` granularity and "sync auto-created columns" language in
  `LtiLineItem`/`LtiDeepLinking` (plus the same comment's "0.0 while still
  unlinked" claim, which the review didn't flag but predates `skip_zero?`),
  and this file's four current-path `spec/staging/` references.
- [x] **`lti.student_overview.empty` = `"[none]"` is intentional copy.**
  Operator-confirmed 2026-07-30 — the review read it as an unfilled stub; it
  is the deliberate label for an empty list.
- [x] **The awaiting-approval message's four collapsed causes stay
  collapsed.** _(Operator decision 2026-07-30.)_ An instructor whose courses
  have all ended/been withdrawn is a rare state, and every cause has the same
  remedy the message already points at — go to the Dashboard, where the
  courses' actual state is visible. Splitting the copy per cause was
  considered and not taken.

## Codex review follow-ups (2026-07-30)

The seventh review round (Codex / GPT-5, at `398e021c6`; a Claude verification
pass at the same head found everything prior verified plus one cosmetic
residual, also fixed here). All three findings confirmed and fixed.

- [x] **Reservations now release on a failed form build.** The pending
  reservation used to commit before `BuildLtiDeepLinkForm`'s LTIAAS call, and
  the discovery job that would clean it up was only scheduled after a
  successful build — so a transient failure squatted the gradables for the
  whole 30-minute lease and the instructor's immediate retry 422'd.
  `ReserveLtiLineItems` now tracks its rows and exposes `release`;
  `deep_link_select` releases on any build failure before re-raising into the
  in-frame error handler. Controller spec covers failure-then-successful-retry.
- [x] **Reservation expiry is an atomic conditional destroy.**
  `expire_if_abandoned` used to check a row snapshot loaded before the remote
  fetch, then `destroy!` unconditionally — a launch adopting the reservation
  in between would have its live, bound mapping deleted.
  `LtiLineItem#expire_reservation!` re-checks `pending?` and the cutoff under
  `with_lock`; model specs cover the adopted-after-load race directly.
- [x] **`docs/canvas_dev_setup.md` reconciled — and the manual path removed
  outright.** The data-flow bullet now includes stored enrollment status; the
  three lateness-marker claims are gone (exercise comments are blank; the
  trainings note is the only comment); the stale "Anonymized choice does not
  reach the installed tool" claim is replaced by the `?privacyLevel=anonymous`
  resolution (dropping the pointer to an uncommitted `.claude/` brief). The
  installation-handoff `[PLACEHOLDER]` was resolved by operator decision
  rather than an answer: **the manual-registration walkthrough is deleted** —
  every install, the test Canvas included, uses the Dynamic Registration flow
  the public guide documents — and the section's institutional-review
  material (VPAT, HECVAT, data flow) survives as its own section.
- [x] The verification pass's cosmetic residual ("auto-created trainings
  roll-up" phrasing in the picker comment) is fixed.

## Copy placeholders from the 2026-07-30 pass

- [x] **Fill the eleven new `[PLACEHOLDER]` strings in `config/locales/en.yml`.**
  _(Operator filled all eleven 2026-07-30; `grep '\[PLACEHOLDER'` across `app/`,
  `config/`, and `spec/` is clean again, and the view-rendering specs pass with
  the real strings.)_ What each needed:
  - `lms_integration.last_roster_sync_error` — staff sidebar notice that the most
    recent roster sync from the LMS failed (sibling of "Last sync error").
  - `lti.status.roster_sync_error` — instructor-facing in-Canvas notice that the
    roster sync failed, parallel to "There was an error syncing the grades."
  - `lti.assignment_view.status.removed_in_lms` — short pill label for a
    connected student whose Canvas enrollment is now inactive or deleted.
  - `lti.setup.no_courses_yet` — instructor with zero Dashboard courses: create
    one first, then relaunch.
  - `lti.setup.link_conflict_error` — instructor-facing setup link-conflict
    error (points at Wiki Ed staff).
  - `lti.setup.duplicate_link_error` — this Canvas identity is already linked to
    a different Dashboard account; name the sign-in-with-that-account remedy.
  - `lti.deep_link.forbidden_header` / `lti.deep_link.forbidden_explanation` —
    a non-instructor opened the import picker.
  - `lti.launch_error.header` / `lti.launch_error.explanation` — the launch
    couldn't be verified (expired ltik / LTIAAS outage); remedy: reload the
    Canvas page.
  - `lti.student_overview.empty` — linked course whose timeline has no content
    yet.

## Published-document notices (2026-07-29)

- [x] **Permanent AI disclosure on `/lti/guide`, and draft banners retired.** The
  guide's only AI attribution had been a clause inside its "Draft — work in
  progress" banner, so the disclosure would have vanished the moment the banner did.
  Both that banner and the HECVAT's are now permanent "About this…" notes carrying
  the same substance — what the document is, that Claude Code drafted it, and who
  reviewed it — without the will-be-finalized framing. `docs/vpat.md` already had a
  permanent note of this shape and was left alone.
- [x] **Blockquotes are styled on the rendered-Markdown pages.** They carry these
  notices, and unstyled they rendered as ordinary indented prose — a disclosure a
  reader skims past as body text is not much of a disclosure. Flagged by the third
  review; `_accessibility_report.styl` now gives them a left rule and a tinted
  ground, which applies to `/accessibility`, `/lti/guide`, and `/hecvat`.
- [x] **HECVAT REQU-04 answered Yes, and the AI tab reconciled.** _(2026-07-29.)_
  Sage changed REQU-04 from No to Yes, which made fourteen AI-tab answers
  self-contradictory: each was N/A on the stated ground that "there are no AI
  features (see REQU-04)". Resolved as:
  - **Ten stay N/A**, rewritten to stand on what is still true — Wiki Education
    develops, trains, and hosts no model of its own — rather than on the retired
    claim. Sage's framing carries these: the AI in use is two traditional ML
    classifiers, not open-ended generative AI, so the LLM and training-data
    questions genuinely don't apply.
  - **AIGN-02 (disableable per tenant/user): No.** There is no such control.
    `Features.wiki_ed?`, `wiki.en_wiki?` and the course-still-running check bound
    *where* LLM detection applies; none is a setting an institution can change, and
    there is no AI-specific feature flag anywhere.
  - **AIPL-02 (AI risks identified/measured): No**, and **AIGN-03 (staff
    responsible-AI training): No**, both with the classifier-vs-generative
    rationale.
  - **AIPL-03 / AIPL-04 (disable / re-enable on incident): Yes** — withdrawing the
    Pangram credential (`ENV['pangram_api_key']`) stops the calls without a
    release; restoring it resumes them.
  - **AISC-03 (logging with user, date, action): Yes** — `revision_ai_scores`
    records the contributing user, course, article, revision, check type, whether
    the check was automatic or run by a named staff member, and the timestamp.
  - **DPAI-02** keeps its **No**, rejustified on what the services actually
    receive, and now discloses that a Pangram submission produces a report at a URL
    that is not access-controlled, whose content is the public Wikipedia text
    submitted.
  - **Originality.ai deliberately omitted**, per Sage: `lib/originality_api.rb` is
    reached only from `/ai_tools`, which is `require_admin_permissions`-gated, run
    manually and rarely by staff, and operates on public Wikipedia text. REQU-04's
    note now describes what runs "as part of normal operation" and mentions the
    admin-only evaluation page in general terms, so the boundary is stated without
    listing a service the product does not call programmatically.
  - **DPAI-03's subprocessor list** now includes New Relic (transaction and error
    traces carry request paths, and Dashboard paths contain course slugs and
    Wikipedia usernames) and Salesforce (course-level records for Wiki Education's
    own programs — enumerated from `PushCourseToSalesforce#base_salesforce_fields`,
    which sends titles, URLs, dates, participant and edit counts, assignment
    settings and AI-alert counts, and no student names or emails). The list also now
    says why the machine-learning services aren't on it: they receive public
    Wikipedia content, not personal or institutional data. THRD-02 carries no
    parallel list, so there was only one copy to update.

## Gallery scope (decided 2026-07-29)

- [x] **`full_course` keeps its own flow.** With every flow now provisioned by the
  real wizard, its shot is close to `canvas_gradebook`'s — same 9-column gradebook
  from the same timeline, differing mainly in being captured at 2200px so every
  column fits. Folding it in would have saved a Canvas course and ~3.5 minutes per
  harvest. Sage's call is to keep it: the deliberately wide, everything-visible
  gradebook is worth its own section for reviewers. Not revisited unless harvest
  runtime becomes a problem.
