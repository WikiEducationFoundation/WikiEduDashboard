# VPAT 2.5 (WCAG edition) — Wiki Education Dashboard

*This report was prepared with AI assistance (Claude Code),
grounded in the source code state of the Wiki Education Dashboard
and in operational context supplied by Wiki Education Foundation
staff. Conformance evaluations and remarks were verified against
current product state by Wiki Education Foundation engineering
before publication.*

---

## Name of Product / Version

Wiki Education Dashboard — `dashboard.wikiedu.org`.

## Report Date

2026-06-01

## Product Description

Web application that supports instructors and students contributing to
Wikipedia and sister projects as part of for-credit university courses.
Public-facing course pages, a student-facing assignment workflow, an
instructor-facing course-management surface, and an admin surface for
Wiki Education Foundation staff.

## Contact Information

Sage Ross, Chief Technology Officer, Wiki Education Foundation —
<sage@wikiedu.org>. Accessibility feedback may also be submitted via
the public dashboard FAQ at <https://dashboard.wikiedu.org/faq/23>.

## Notes

- This attestation covers the Wiki Education Dashboard as deployed at
  `dashboard.wikiedu.org`. The codebase also runs the Programs &
  Events Dashboard at `outreachdashboard.wmflabs.org`; that
  deployment is operated by the Wikimedia Foundation and is not
  covered by this attestation.
- Canvas LTI integration surfaces are under development and are
  not yet in production. They will require separate evaluation when
  shipped.
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
   **ArticleViewer authorship-highlighting** view, which conveys
   per-author contribution via mouseover-only labels on colored
   text spans and is therefore effectively unusable with a screen
   reader or via keyboard (impact is limited to internal staff
   use; see Method 6); and (b) the **survey-taking flow**,
   which is known to have screen-reader compatibility limitations
   and has not been recently re-verified end-to-end with a screen
   reader (no survey-related accessibility complaints have come
   through the field-feedback channels).
4. **Spot manual review** of specific patterns (heading order,
   landmark usage, color contrast on Stylus-defined colors).
5. **Structured visual inspection under layout-stress conditions**
   via three manual-only Capybara specs:
   `spec/features/resize_text_check.rb` (200% browser zoom),
   `spec/features/reflow_check.rb` (320 CSS pixel viewport via
   Chrome DevTools Protocol device metrics override), and
   `spec/features/text_spacing_check.rb` (the WCAG 1.4.12 text-
   spacing override — line-height 1.5, letter-spacing 0.12em,
   word-spacing 0.16em, paragraph spacing 2em — injected as a
   stylesheet). All three visit the same 13 representative pages
   — logged-out home; explore; the seven course-page tabs (home,
   timeline, students, articles, uploads, activity, resources)
   against a realistically populated course; the course-creator
   modal; survey admin; admin dashboard; and onboarding — and
   pause for human inspection at each. Re-runnable as the product
   evolves.
6. **Ongoing field-feedback channels.** Wiki Education collects
   regular survey feedback from instructors (who in turn relay
   student-reported issues) and accepts direct accessibility
   feedback via the public dashboard FAQ. As of this attestation,
   no accessibility complaints from the field have remained
   unaddressed in normal development cycles. The technical
   limitations of the ArticleViewer authorship view carved out
   from Method 3 have not been reported through these channels by
   any student or instructor; the known impact of that view is
   confined to internal Wiki Education staff use.

**Methods NOT used in this evaluation** (gaps for v2):

- Structured manual keyboard-only navigation testing.
- Structured manual screen-reader testing on the surfaces the
  JAWS-using admin does not routinely exercise (student-role
  assignment wizard, training-module taking flow, survey-taking
  flow, ArticleViewer authorship view).
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
  criterion. Used here for the small number of Level A/AA rows
  where the current evaluation methods do not yet provide
  evidence.

---

## WCAG 2.1 Report

### Table 1: Success Criteria, Level A

| Criterion | Conformance Level | Remarks and Explanations |
|---|---|---|
| **1.1.1 Non-text Content** | Partially Supports | axe-locked pages enforce alt-text presence on images and accessible names on icon-only buttons. A minority of chart and graph components render an adjacent localized text description; most do not. Decorative SVGs are not consistently marked `aria-hidden`. |
| **1.2.1 Audio-only and Video-only (Prerecorded)** | Not Applicable | The Dashboard does not present prerecorded audio-only or video-only content as a primary feature. Training modules embed third-party video which falls under those providers' attestations. |
| **1.2.2 Captions (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.2.3 Audio Description or Media Alternative (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.3.1 Info and Relationships** | Partially Supports | axe-locked pages enforce heading order, list semantics, form-label association, and landmark presence. `jsx-a11y/label-has-associated-control` is enforced in the React layer. Admin and core course-page surfaces validated through daily JAWS use. The ArticleViewer authorship view does not expose author attribution to assistive tech. The survey-taking flow has not been recently re-evaluated for programmatic relationship exposure. |
| **1.3.2 Meaningful Sequence** | Partially Supports | Admin and core course-page surfaces validated through daily JAWS use. Student-only assignment-wizard, training-module, and survey-taking flows have not been structurally evaluated for reading-order vs. visual-order divergence. |
| **1.3.3 Sensory Characteristics** | Partially Supports | Most affordances combine shape, position, and text labels. A comprehensive inventory of color-only signals (e.g. status indicators in analytics, alert severity badges, and AI-score plots) has not been done. |
| **1.4.1 Use of Color** | Partially Supports | Status indicators typically combine color with text or icons, but a structured audit has not been done. |
| **1.4.2 Audio Control** | Not Applicable | No auto-playing audio. |
| **2.1.1 Keyboard** | Supports | `jsx-a11y/click-events-have-key-events` and `jsx-a11y/no-static-element-interactions` are enforced in the React layer, and axe-locked pages pass keyboard-relevant axe rules. The two drag-and-drop reorder interactions in the product (timeline block reordering and the admin-only training-module composer slide reordering) each include redundant keyboard-accessible Move up / Move down buttons with localized `aria-label`s, so the drag affordance is not the only path to the action. |
| **2.1.2 No Keyboard Trap** | Partially Supports | The shared Modal and Confirm components do not implement a focus trap, an Escape-key handler, or focus return to the trigger on close. A keyboard user is therefore not trapped (they can Tab into the page underneath), so the strict criterion is not violated; but the focus-management behavior fails 2.4.3 and is the inverse of what users expect from a modal. |
| **2.1.4 Character Key Shortcuts** | Not Applicable | The product does not implement single-character key shortcuts. |
| **2.2.1 Timing Adjustable** | Not Applicable | The product does not impose time limits on user interactions. |
| **2.2.2 Pause, Stop, Hide** | Supports | The product does not include moving, blinking, scrolling, or auto-updating content that starts automatically. The survey-taking flow uses a slick.js carousel between questions, but it advances only on user action (no autoplay). |
| **2.3.1 Three Flashes or Below Threshold** | Supports | The product contains no flashing content. |
| **2.4.1 Bypass Blocks** | Supports | Pages use HTML5 landmarks for assistive-tech navigation, with a `<main>` element on every layout. A visible "Skip to main content" link is rendered as the first focusable element on every navigation-bearing layout; it is positioned offscreen by default and revealed on focus, and targets the main landmark. |
| **2.4.2 Page Titled** | Supports | All pages set a descriptive `<title>` via the Rails `content_for(:title)` mechanism. |
| **2.4.3 Focus Order** | Partially Supports | Admin and core course-page surfaces validated through daily JAWS use. The shared Modal does not return focus to the triggering control on close, and only the Confirm modal moves focus into the dialog on open. Multi-step flows (course-creation wizard, onboarding) have not been structurally evaluated for focus management on step transitions. |
| **2.4.4 Link Purpose (In Context)** | Partially Supports | axe-locked pages enforce accessible names on links; `jsx-a11y/anchor-has-content` and `jsx-a11y/anchor-is-valid` enforced. Some link text (e.g., "View", "Edit" in list rows) relies on surrounding visual context that may not be exposed to assistive tech. |
| **2.5.1 Pointer Gestures** | Supports | Most interactions are single-point. The two path-based pointer gestures in the product (timeline block reordering and the admin-only training-module composer slide reordering) each include a redundant single-point alternative (Move up / Move down buttons), so the path-based gesture is not the only path to the action. |
| **2.5.2 Pointer Cancellation** | Not Evaluated | Custom click handlers have not been audited for up-event vs. down-event triggering. |
| **2.5.3 Label in Name** | Partially Supports | axe-locked pages enforce accessible-name matching for most controls. Icon-button accessible names (set via `aria-label`) sometimes differ from their visible tooltip text. |
| **2.5.4 Motion Actuation** | Not Applicable | No motion-based interactions. |
| **3.1.1 Language of Page** | Supports | The `<html lang>` attribute is set per request locale; axe-checked on every axe-locked page. |
| **3.2.1 On Focus** | Not Evaluated | Has not been structurally tested but no patterns are known to cause context changes on focus. |
| **3.2.2 On Input** | Partially Supports | Form controls generally do not auto-submit. Some select menus trigger immediate filter/sort updates on change; these are documented as part of the interaction pattern but the behavior change has not been audited for surprise. |
| **3.3.1 Error Identification** | Supports | Server-side form errors are rendered as text in the page. Errored fields automatically carry `aria-invalid="true"`, and every form's top-of-form error summary carries `role="alert"` so the error text is announced on submission. Per-field `aria-describedby` linking each error message to its specific field is a future enhancement but is not strictly required by 3.3.1. |
| **3.3.2 Labels or Instructions** | Supports | Forms use `<label>` association; `jsx-a11y/label-has-associated-control` is enforced in CI; axe-locked pages pass label rules. |
| **4.1.1 Parsing** | Supports | This criterion was made obsolete by WCAG 2.2. For WCAG 2.1, the product passes axe's parsing rules on axe-locked pages and uses HAML/JSX templating that produces well-formed HTML. |
| **4.1.2 Name, Role, Value** | Partially Supports | axe-locked pages enforce ARIA attribute validity and accessible-name presence on interactive controls. The shared Modal declares `role="dialog"` and `aria-modal="true"`, and each call site supplies an accessible name. Custom widgets (multi-step wizard step indicators, custom toggle controls in surveys) have not been comprehensively audited, and the Modal does not implement focus-trap or focus-return on close (see 2.4.3). |

### Table 2: Success Criteria, Level AA

| Criterion | Conformance Level | Remarks and Explanations |
|---|---|---|
| **1.2.4 Captions (Live)** | Not Applicable | No live audio/video. |
| **1.2.5 Audio Description (Prerecorded)** | Not Applicable | No Dashboard-hosted prerecorded video. |
| **1.3.4 Orientation** | Supports | The product does not lock orientation. |
| **1.3.5 Identify Input Purpose** | Supports | User-info inputs (onboarding form, new-account-request modal, user-profile email field) carry HTML `autocomplete` attributes with WCAG-recognised input-purpose tokens. The product authenticates via OAuth (MediaWiki) and has no traditional password forms; the inputs that do collect user-purpose data are annotated. |
| **1.4.3 Contrast (Minimum)** | Partially Supports | axe-locked pages enforce 4.5:1 contrast for normal text and 3:1 for large text. Pages without an axe-clean lock have not been verified. |
| **1.4.4 Resize Text** | Supports | At 200% browser zoom, text remains readable and functionality remains accessible across the surfaces verified under Evaluation Method 5 (13 pages including all seven course-page tabs). Horizontal page scroll appears at high zoom on most pages, which 1.4.4 permits; the stricter 1.4.10 Reflow criterion is reported separately. Some button labels with longer localized text wrap onto a second line at 200% — layout adaptation, not loss of content or functionality. |
| **1.4.5 Images of Text** | Supports | The product does not use images of text for content; text in the UI is rendered as HTML. Logos are the only exception, which is permitted. |
| **1.4.10 Reflow** | Partially Supports | At a 320 CSS pixel viewport width, the core student- and instructor-facing surfaces after a course is underway — the course-page tabs (home, timeline, students, articles, uploads, activity, resources), explore, the logged-out home, admin dashboard, survey admin, and onboarding — remain usable: layout adapts vertically, navigation wraps, the timeline relocates its sidebar above the weeks list, and content remains reachable. The **course-creator modal** does not adapt to 320 CSS pixels and is not currently supported at that viewport size; the wizard's multi-step form layout would need substantial restructuring. Some course-page tables (students, articles, uploads list view) reflow vertically for most columns but retain a horizontal scroll for their tabular data; this is a known pattern that some 1.4.10 audits treat as a Partial pass and others treat as a fail. |
| **1.4.11 Non-text Contrast** | Partially Supports | UI component boundaries (form fields, buttons in their resting state) have not been comprehensively audited for 3:1 contrast against adjacent colors. |
| **1.4.12 Text Spacing** | Supports | With the WCAG-mandated text-spacing override applied (line-height 1.5, letter-spacing 0.12em, word-spacing 0.16em, paragraph-spacing 2em), text on the verified surfaces does not clip and functionality remains accessible. Minor caveat: the sticky table header on the students tab uses a hardcoded `top` offset that assumes the default global-nav height; at increased text spacing the nav grows taller and the sticky header sits at a slightly off position relative to the table body. Table content remains reachable by scrolling. |
| **1.4.13 Content on Hover or Focus** | Partially Supports | Some controls deliver additional content via mouseover-only tooltips (the HTML `title` attribute or equivalent), which does not satisfy the criterion's hoverable / persistent / dismissable requirements and is not keyboard-accessible. The most consequential case is the **ArticleViewer authorship view**, where per-author attribution is revealed only on mouseover of colored text spans — making the information effectively unavailable to screen-reader and keyboard users, even though the underlying labels exist. |
| **2.4.5 Multiple Ways** | Supports | The product offers a global search, a campaign and course browse hierarchy, a primary navigation, and an "Explore" categorical browse. |
| **2.4.6 Headings and Labels** | Supports | axe-locked pages enforce heading-order and label-presence rules. Heading text and form labels are descriptive of their content. |
| **2.4.7 Focus Visible** | Supports | Buttons display a visible focus indicator when reached via keyboard while remaining un-ringed for mouse clicks (the site-wide CSS reset uses `:focus-visible`). Many specific button modules and form controls also define their own complementary focus styles. Admin and core course-page surfaces validated through daily JAWS use. |
| **3.1.2 Language of Parts** | Partially Supports | The page-level `lang` attribute is set, but content embedded from Wikipedia in scripts other than the page language (e.g., Arabic or Japanese article titles shown in a Latin-script UI) does not carry per-element `lang` markup. |
| **3.2.3 Consistent Navigation** | Supports | The global header, primary navigation, and footer are rendered from shared layouts and appear in consistent positions across the product. |
| **3.2.4 Consistent Identification** | Supports | Components with the same function (e.g., the "Edit" button on a course detail row) use the same icon, accessible name, and position throughout the product. |
| **3.3.3 Error Suggestion** | Partially Supports | Server-side form validation in some cases suggests specific corrections (e.g., "Email is already taken"); other failure modes report only that an error occurred. |
| **3.3.4 Error Prevention (Legal, Financial, Data)** | Not Applicable | The product does not process legal, financial, or other transactions where errors would have legal or financial consequences. |
| **4.1.3 Status Messages** | Partially Supports | ARIA live regions and `role="alert"` are used for in-page notifications, the weekday picker, the admin-notes panel, modal confirmations, and the top-of-form error summary on every server-rendered form. Loading-state announcements during course-update polling and other long-running async updates have not been structurally evaluated and are likely silent to assistive tech. |

---

## Legal Disclaimer

This Voluntary Product Accessibility Template (VPAT) is provided for informational purposes only. Although the information herein is provided in good faith based on the analysis of the product as of the date of publication, it is subject to change without notice. Electronic information technology is a dynamic field, and accessibility standards and assistive technologies continue to evolve.

The VPAT does not constitute a legally binding guarantee or certification of compliance with any accessibility standard (such as WCAG or Section 508). Conformance levels are subject to interpretation and the context in which the product is used. Reliance on this report is at your own risk. Wiki Education makes no warranty, express or implied, regarding the accuracy of the information contained herein, including any warranty of merchantability or fitness for a particular purpose, and Wiki Education disclaims any liability for inaccuracies, omissions, or any decisions or actions taken based upon the information provided in this report.

## Signature

**Sage Ross**, Chief Technology Officer, Wiki Education Foundation

Attested 2026-06-01
