# VPAT 2.5 (WCAG edition) — Wiki Education Dashboard — Working Draft

**STATUS: working draft, not signed.** This file is the living source
for the Wiki Education Dashboard's Voluntary Product Accessibility
Template self-attestation. It is not itself a signed VPAT. When an
external request needs a signed, dated artifact, the appropriate
process is to take a snapshot of this file, fill in the placeholder
fields (Report Date, Contact Information, Legal Disclaimer,
Signature), have a Wiki Education Foundation representative review
and sign it, and distribute that snapshot as the signed VPAT. This
working draft is then updated in place as the product changes and
new evaluation evidence accumulates, so that the next signed
snapshot reflects the most current state.

The initial draft of this document was produced with AI assistance
(Claude Code) on 2026-05-15, grounded in the repo state and in
operational context supplied by Wiki Ed staff. Conformance
evaluations and remarks should be verified against current product
state before each signed snapshot.

---

## Name of Product / Version

Wiki Education Dashboard — `dashboard.wikiedu.org`.

## Report Date

*Filled in at each signed snapshot from the current calendar date.*

## Product Description

Web application that supports instructors and students contributing to
Wikipedia and sister projects as part of for-credit university courses.
Public-facing course pages, a student-facing assignment workflow, an
instructor-facing course-management surface, and an admin surface for
Wiki Education Foundation staff.

## Contact Information

*Filled in at each signed snapshot.*

## Notes

- This attestation covers the Wiki Education Dashboard as deployed at
  `dashboard.wikiedu.org`. The codebase also runs the Programs &
  Events Dashboard at `outreachdashboard.wmflabs.org`; that
  deployment is operated by the Wikimedia Foundation and is not
  covered by this attestation.
- Canvas LTI integration surfaces are under development and are
  not yet in production. They will require separate evaluation when
  shipped and this working draft will be updated accordingly.
- Wikipedia article content shown in iframes (the Article Viewer)
  is rendered by Wikipedia/Wikimedia and is governed by their
  accessibility statement, not this one.

## Evaluation Methods Used

1. **Automated testing via axe-core** (`axe-core-rspec` 4.11.3) at the
   feature-spec layer. ~99 `be_axe_clean` assertions across ~52
   spec files lock a substantial subset of public, course, admin,
   training, survey, and analytics pages against the default axe
   ruleset (which covers WCAG 2.0 A/AA, WCAG 2.1 A/AA, and some
   best-practice rules). Pages with an axe-clean assertion in CI
   are referred to below as "axe-locked".
2. **Static linting** via `eslint-plugin-jsx-a11y` (recommended
   ruleset) enforced on the React codebase, covering interactive
   semantics, ARIA usage, label associations, and keyboard handler
   patterns at code-review time.
3. **Day-to-day JAWS usage** by a Wiki Education staff administrator,
   who operates the production Dashboard exclusively via JAWS — both
   the admin surfaces and the core public/course-page surfaces
   (course overview and the students/articles/timeline tabs). This is
   not a structured audit but it does constitute ongoing real-world
   screen-reader validation of those surfaces; defects observed are
   reported and fixed in the normal development cycle. Two
   known-problem areas are carved out of this validation: (a) the
   **ArticleViewer authorship-highlighting** view (the WhoColor
   integration at `app/assets/javascripts/components/common/ArticleViewer/`),
   which conveys per-author contribution via color-only spans and is
   known to be unusable with a screen reader; and (b) the **survey-
   taking flow**, which has historically had screen-reader issues
   and has not been re-verified end-to-end since the recent axe-clean
   remediation sprint.
4. **Spot manual review** of specific patterns flagged during the
   axe-clean remediation sprint (heading order, landmark usage,
   color contrast on Stylus-defined colors).
5. **Structured 200% browser-zoom visual inspection** via the
   manual-only Capybara spec at
   `spec/features/resize_text_check.rb`. The spec applies a 200%
   page zoom and pauses for human inspection on 13 representative
   pages: logged-out home; explore; the seven course-page tabs
   (home, timeline, students, articles, uploads, activity,
   resources) against a realistically populated course; the
   course-creator modal; survey admin; admin dashboard; and
   onboarding. Re-runnable as the product evolves.

**Methods NOT used in this evaluation** (gaps for v2):

- Structured manual keyboard-only navigation testing.
- Structured manual screen-reader testing on the surfaces the
  JAWS-using admin does not routinely exercise (student-role
  assignment wizard, training-module taking flow, survey-taking
  flow, ArticleViewer authorship view).
- Reflow testing at 320 CSS pixels viewport width (WCAG 1.4.10).
  The 200% browser-zoom spec exercises layout adaptation at the
  narrow effective widths produced by zoom, but not strictly at
  the 320-pixel viewport size required by 1.4.10.
- Text-spacing override testing (WCAG 1.4.12).
- Mobile and touch-only interaction testing.
- Third-party audit.

## Applicable Standards/Guidelines

| Standard | Included In Report |
|---|---|
| Web Content Accessibility Guidelines 2.1 Level A | Yes |
| Web Content Accessibility Guidelines 2.1 Level AA | Yes |
| Web Content Accessibility Guidelines 2.1 Level AAA | No |
| Revised Section 508 standards as published by the U.S. Access Board | Indirectly (via WCAG 2.0 A/AA, which is a subset of WCAG 2.1 A/AA) |
| EN 301 549 (European harmonised accessibility standard) | No |

## Terms Used

- **Supports**: The functionality of the product has at least one
  method that meets the criterion without known defects, or meets
  with equivalent facilitation.
- **Partially Supports**: Some functionality of the product does not
  meet the criterion.
- **Does Not Support**: The majority of product functionality does
  not meet the criterion.
- **Not Applicable**: The criterion is not relevant to the product.
- **Not Evaluated**: The product has not been evaluated against the
  criterion. (Allowable only for Level AAA criteria, which are not
  reported here.) In this draft we use "Not Evaluated" honestly for
  Level A/AA rows where the v1 evaluation methods do not give us
  evidence; the published v2 attestation should reduce this set.

---

## WCAG 2.1 Report

### Table 1: Success Criteria, Level A

| Criterion | Conformance Level | Remarks and Explanations |
|---|---|---|
| **1.1.1 Non-text Content** | Partially Supports | axe-locked pages enforce alt-text presence on `<img>` and accessible names on icon-only buttons. Three chart components (`course_ores_plot`, `campaign_ores_plot`, one `campaign_stats` graph) render an adjacent I18n-localized text description; the remaining ~7 chart/graph components (`wp10_graph`, `edit_size_graph`, `article_graphs`, `course_quality_progress_graph`, `alerts_trends_graph`, `likelihood_distribution_graph`, `scores_trends_graph`) do not. SVG decorative graphics are not consistently marked `aria-hidden`. The **ArticleViewer authorship view** conveys per-author contributions via color-only highlighted text and lacks a non-color text alternative. |
| **1.2.1 Audio-only and Video-only (Prerecorded)** | Not Applicable | The Dashboard does not present prerecorded audio-only or video-only content as a primary feature. Training modules embed third-party video which falls under those providers' attestations. |
| **1.2.2 Captions (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.2.3 Audio Description or Media Alternative (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.3.1 Info and Relationships** | Partially Supports | axe-locked pages enforce heading order, list semantics, form-label association, and landmark presence. `jsx-a11y/label-has-associated-control` is enforced in the React layer. Admin and core course-page surfaces validated through daily JAWS use. The ArticleViewer authorship view does not expose author attribution to assistive tech. The survey-taking flow has not been re-evaluated for programmatic relationship exposure since the axe-clean remediation. |
| **1.3.2 Meaningful Sequence** | Partially Supports | Admin and core course-page surfaces validated through daily JAWS use. Student-only assignment-wizard, training-module, and survey-taking flows have not been structurally evaluated for reading-order vs. visual-order divergence. |
| **1.3.3 Sensory Characteristics** | Partially Supports | Most affordances combine shape, position, and text labels. A comprehensive inventory of color-only signals (e.g. status indicators in analytics, alert severity badges, and AI-score plots) has not been done. |
| **1.4.1 Use of Color** | Partially Supports | Same as 1.3.3 for most surfaces — status indicators typically combine color with text or icons, but a structured audit has not been done. The **ArticleViewer authorship view** is a definitive color-only failure for this criterion: it conveys per-author contribution exclusively through highlighted color spans. |
| **1.4.2 Audio Control** | Not Applicable | No auto-playing audio. |
| **2.1.1 Keyboard** | Supports | `jsx-a11y/click-events-have-key-events` and `jsx-a11y/no-static-element-interactions` enforced in the React layer; axe-locked pages pass keyboard-relevant axe rules. The two drag-and-drop reorder interactions in the product (timeline block reordering, admin-only training-module composer slide reordering) each ship redundant keyboard-accessible Move up / Move down buttons (`orderable_block.jsx`, `training_module_composer/components/slide_sidebar.jsx`) with localized `aria-label`s, so the drag affordance is not the only path to the action. |
| **2.1.2 No Keyboard Trap** | Partially Supports | Reviewed the shared `Modal` and `Confirm` components (`app/assets/javascripts/components/common/modal.jsx`, `confirm.jsx`). Neither implements a focus trap, an Escape-key handler, or focus return to the trigger on close. In practice this means a keyboard user is *not* trapped (they can Tab into the page underneath), so the strict criterion is not violated; but the focus-management behavior fails 2.4.3 (see below) and is the inverse of what users expect from a modal. |
| **2.1.4 Character Key Shortcuts** | Not Applicable | The product does not implement single-character key shortcuts. |
| **2.2.1 Timing Adjustable** | Not Applicable | The product does not impose time limits on user interactions. |
| **2.2.2 Pause, Stop, Hide** | Partially Supports | The onboarding flow includes a slick.js carousel that auto-advances slides; users can interact with controls to pause but a comprehensive pause/stop/hide affordance has not been verified. No other auto-updating content. |
| **2.3.1 Three Flashes or Below Threshold** | Supports | The product contains no flashing content. |
| **2.4.1 Bypass Blocks** | Supports | Pages use HTML5 landmarks for assistive-tech navigation; the application layout sets `%main#main` with `<nav>` and `<header>` in the shared partials. A visible "Skip to main content" link is rendered as the first focusable element in every navigation-bearing layout (`app/views/shared/_skip_link.html.haml`, positioned offscreen by default and revealed on `:focus` via the `.skip-link` Stylus module); it targets `#main`. |
| **2.4.2 Page Titled** | Supports | All pages set a descriptive `<title>` via the Rails `content_for(:title)` mechanism. |
| **2.4.3 Focus Order** | Partially Supports | Admin and core course-page surfaces validated through daily JAWS use. **Verified gap:** the shared `Modal` component does not return focus to the triggering control on close, and only the `Confirm` modal explicitly moves focus into the dialog on open (focusing the confirm button). Multi-step flows (course-creation wizard, onboarding) have not been structurally evaluated for focus management on step transitions. |
| **2.4.4 Link Purpose (In Context)** | Partially Supports | axe-locked pages enforce accessible names on links; `jsx-a11y/anchor-has-content` and `jsx-a11y/anchor-is-valid` enforced. Some link text (e.g., "View", "Edit" in list rows) relies on surrounding visual context that may not be exposed to assistive tech. |
| **2.5.1 Pointer Gestures** | Supports | Most interactions are single-point. The two path-based pointer gestures in the product (timeline block reordering, admin-only training-module composer slide reordering) each ship a redundant single-point alternative (Move up / Move down buttons), so the path-based gesture is not the only path to the action. |
| **2.5.2 Pointer Cancellation** | Not Evaluated | Custom click handlers have not been audited for up-event vs. down-event triggering. |
| **2.5.3 Label in Name** | Partially Supports | axe-locked pages enforce accessible-name matching for most controls. Icon-button accessible names (set via `aria-label`) sometimes differ from their visible tooltip text. |
| **2.5.4 Motion Actuation** | Not Applicable | No motion-based interactions. |
| **3.1.1 Language of Page** | Supports | The `<html lang>` attribute is set per request locale; axe-checked on every axe-locked page. |
| **3.2.1 On Focus** | Not Evaluated | Has not been structurally tested but no patterns are known to cause context changes on focus. |
| **3.2.2 On Input** | Partially Supports | Form controls generally do not auto-submit. Some select menus trigger immediate filter/sort updates on change; these are documented as part of the interaction pattern but the behavior change has not been audited for surprise. |
| **3.3.1 Error Identification** | Supports | Server-side form errors are rendered as text in the page (via Rails' `errors.full_messages` in HAML partials). Errored fields automatically carry `aria-invalid="true"` via a global `field_error_proc` override in `config/initializers/aria_field_errors.rb`, so screen readers can identify which specific field failed. Every HAML form's top-of-form error summary carries `role="alert"` so the error text is announced on submission. Per-field `aria-describedby` linking the error message text to the field is a future enhancement (would strengthen 3.3.3 Error Suggestion further) but is not strictly required by 3.3.1. |
| **3.3.2 Labels or Instructions** | Supports | Forms use `<label>` association; `jsx-a11y/label-has-associated-control` is enforced in CI; axe-locked pages pass label rules. |
| **4.1.1 Parsing** | Supports | This criterion was made obsolete by WCAG 2.2. For WCAG 2.1, the product passes axe's parsing rules on axe-locked pages and uses HAML/JSX templating that produces well-formed HTML. |
| **4.1.2 Name, Role, Value** | Partially Supports | axe-locked pages enforce ARIA attribute validity and accessible-name presence on interactive controls. `jsx-a11y/aria-role` and `jsx-a11y/aria-props` enforced in the React layer. The shared `Modal` component now declares `role="dialog"` and `aria-modal="true"` (`app/assets/javascripts/components/common/modal.jsx`), and each call site supplies an accessible name via `ariaLabel` or `ariaLabelledBy` pointing to the modal's inline heading; the `Confirm` modal references its message text via `aria-labelledby="confirm-message"`. **Remaining gaps:** custom widgets (multi-step wizard step indicators, custom toggle controls in surveys) have not been comprehensively audited, and the shared Modal does not yet implement focus-trap or focus-return on close (see 2.4.3). |

### Table 2: Success Criteria, Level AA

| Criterion | Conformance Level | Remarks and Explanations |
|---|---|---|
| **1.2.4 Captions (Live)** | Not Applicable | No live audio/video. |
| **1.2.5 Audio Description (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.3.4 Orientation** | Supports | The product does not lock orientation. |
| **1.3.5 Identify Input Purpose** | Supports | The user-info inputs in the codebase carry the HTML `autocomplete` attribute with WCAG-recognised input-purpose tokens: `autocomplete="name"` and `autocomplete="email"` on the onboarding form (`app/assets/javascripts/components/onboarding/form.jsx`), `autocomplete="username"` and `autocomplete="email"` on the new-account-request modal (`app/assets/javascripts/components/enroll/new_account_modal.jsx`, via a passthrough prop added to the shared `TextInput` component), and `autocomplete="email"` on the user-profile email field (`app/views/user_profiles/_user_form.html.haml`). The product authenticates via OAuth (MediaWiki) and therefore has no traditional password forms; the inputs that *do* collect user-purpose data are now annotated. |
| **1.4.3 Contrast (Minimum)** | Partially Supports | axe-locked pages enforce 4.5:1 contrast for normal text and 3:1 for large text. Several site-wide color tokens were darkened during the axe-clean remediation sprint (`$text_med_header`, `.button.dark` hover, onboarding footer background). Pages without an axe-clean lock have not been verified, including any Stylus modules used only outside the locked routes. |
| **1.4.4 Resize Text** | Supports | At 200% browser zoom, text remains readable and functionality remains accessible across the surfaces verified under Evaluation Method 5 (13 pages including all seven course-page tabs). Horizontal page scroll appears at high zoom on most pages, which 1.4.4 permits; the stricter 1.4.10 Reflow criterion is reported separately. Some button labels with longer localized text wrap onto a second line at 200% — layout adaptation, not loss of content or functionality. |
| **1.4.5 Images of Text** | Supports | The product does not use images of text for content; text in the UI is rendered as HTML. Logos are the only exception, which is permitted. |
| **1.4.10 Reflow** | Not Evaluated | Has not been structurally tested at 320 CSS pixels width. The product has not been audited for horizontal scrolling. |
| **1.4.11 Non-text Contrast** | Partially Supports | UI component boundaries (form fields, buttons in their resting state) have not been comprehensively audited for 3:1 contrast against adjacent colors. Some axe-clean remediation work addressed adjacent issues. |
| **1.4.12 Text Spacing** | Not Evaluated | Has not been tested with user style sheets applying the WCAG-specified text-spacing values. |
| **1.4.13 Content on Hover or Focus** | Partially Supports | Several controls use the HTML `title` attribute for tooltip content; this is a known accessibility limitation (`title`-only tooltips do not satisfy hoverable/persistent/dismissable requirements). Plan to migrate to proper tooltip components is open. |
| **2.4.5 Multiple Ways** | Supports | The product offers a global search, a campaign and course browse hierarchy, a primary navigation, and an "Explore" categorical browse. |
| **2.4.6 Headings and Labels** | Supports | axe-locked pages enforce heading-order and label-presence rules. Heading text and form labels are descriptive of their content. |
| **2.4.7 Focus Visible** | Supports | The site-wide CSS reset declares `button:focus:not(:focus-visible) { outline: none }` together with `button:focus-visible { outline: 2px solid currentColor; outline-offset: 2px }` (`app/assets/stylesheets/_reset.styl`), so every `<button>` element has a visible focus indicator when reached via keyboard while remaining un-ringed for mouse clicks. Many specific button modules and form controls also define their own complementary `:focus` styles. Admin and core course-page surfaces validated through daily JAWS use. |
| **3.1.2 Language of Parts** | Partially Supports | The page-level `lang` attribute is set, but content embedded from Wikipedia in scripts other than the page language (e.g., Arabic or Japanese article titles shown in a Latin-script UI) does not carry per-element `lang` markup. |
| **3.2.3 Consistent Navigation** | Supports | The global header, primary navigation, and footer are rendered from shared layouts and appear in consistent positions across the product. |
| **3.2.4 Consistent Identification** | Supports | Components with the same function (e.g., the "Edit" button on a course detail row) use the same icon, accessible name, and position throughout the product. |
| **3.3.3 Error Suggestion** | Partially Supports | Server-side form validation in some cases suggests specific corrections (e.g., "Email is already taken"); other failure modes report only that an error occurred. |
| **3.3.4 Error Prevention (Legal, Financial, Data)** | Not Applicable | The product does not process legal, financial, or other transactions where errors would have legal or financial consequences. |
| **4.1.3 Status Messages** | Partially Supports | ARIA live regions and `role="alert"` are used in several specific places: the notifications component (`notifications.jsx`, `nav/news/news_notification/notification.jsx`), the weekday picker (`weekday_picker.jsx`), the admin-notes panel (three components with `aria-live="assertive" aria-atomic="true"`), and the `Confirm` modal. Loading-state announcements during course-update polling and other long-running async updates have not been structurally evaluated and are likely silent to assistive tech. |

---

## Legal Disclaimer

*Filled in at each signed snapshot.*

## Signature

*Each signed snapshot of this working draft must be reviewed and
signed by an authorized Wiki Education Foundation representative
before publication.*

---

(VPAT working draft. Initial draft prepared with AI assistance;
maintained in-repo and updated as the product evolves. Signed
snapshots are exported from this file via the process described in
the header.)
