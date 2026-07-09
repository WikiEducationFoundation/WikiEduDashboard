> **Draft — work in progress.** This guide accompanies the in-development Canvas
> integration and will be finalized before it ships to production. It was drafted
> with Claude Code and is pending Wiki Education's review; the `[PLACEHOLDER]`
> markers flag details Wiki Education still needs to fill in.

# Adding the Wiki Education Dashboard to your Canvas

This guide is for **Canvas administrators** at colleges and universities whose
instructors use the [Wiki Education Dashboard](https://dashboard.wikiedu.org) to
run Wikipedia writing assignments. It covers evaluating, installing, and enabling
the Dashboard's Canvas integration.

The integration is an **LTI 1.3** tool, fronted by [LTIAAS](https://ltiaas.com), a
third-party LTI service. Installing it follows the standard Canvas path for any LTI
1.3 tool. The steps below use Canvas's own labels so you can follow along
one-to-one in the admin interface.

## What the integration does

Once installed, the Wiki Education Dashboard becomes an LTI tool in your Canvas:

- **Course-navigation link** — instructors and students open the Dashboard from a
  link in the course's left-hand navigation, already signed in.
- **Roster sync (NRPS)** — students who launch the tool are added to the
  instructor's Dashboard course automatically.
- **Gradebook passback (AGS)** — the training modules and exercises students
  complete on the Dashboard report back as scores in your Canvas gradebook.
- **Assignment integration (Deep Linking)** — instructors can add specific
  Dashboard exercises as Canvas assignments.

## Who installs it, and where

Install the integration on your Canvas instance's **root (institution) account**,
as a Canvas administrator — the same place you manage other institution-wide LTI
tools. It does **not** require Site Admin access (on Instructure-hosted Canvas you
won't have that anyway). You can also install on a **sub-account** to limit the
tool to one division.

Installing on the root account makes the tool *available* everywhere, but you
control whether it actually appears:

- **Opt-in (recommended for a first rollout):** the tool is installed but its
  course-navigation link is off by default; each instructor turns it on for their
  own course. Nothing changes for courses that don't use it.
- **On by default:** the link appears in every course's navigation.

## Before you install: review and approvals

Most institutions review a tool's accessibility and data handling first:

- **Accessibility (VPAT):**
  [dashboard.wikiedu.org/accessibility](https://dashboard.wikiedu.org/accessibility)
  — VPAT 2.5 (WCAG edition), evaluated against WCAG 2.1 A and AA.
- **Security & privacy (HECVAT):**
  [dashboard.wikiedu.org/hecvat](https://dashboard.wikiedu.org/hecvat).
- **What the tool requests from Canvas:** the tool asks for read access to a
  course's roster (NRPS — `contextmembership.readonly`) and permission to create
  and post gradebook line items and scores (AGS). Its placements are limited to
  course navigation, the assignment / deep-linking pickers, and the assignment
  view.
- **What data is shared:** when a student launches the tool, Canvas shares their
  name and course-roster membership with the Dashboard (via LTIAAS) so they can be
  enrolled; the Dashboard sends scores, and links to the students' work, back to
  your gradebook. [PLACEHOLDER - Wiki Education to confirm and expand this
  data-sharing summary so it matches the HECVAT and the privacy policy.]

## What you'll need

- Canvas **root-account administrator** access.
- For the self-service path, Wiki Education's registration URL:
  `https://wikiedu.ltiaas.com/lti/register`. For the manual path, the Dashboard's
  **LTI configuration** [PLACEHOLDER - where an institution obtains the manual
  configuration from Wiki Education].
- About 15 minutes.

## Installation

There are two ways to install, depending on whether your Canvas has the **Dynamic
Registration** feature:

- **Dynamic Registration (recommended):** you paste one URL and Canvas and the
  Dashboard configure everything automatically, including registering your Canvas
  with the tool — no configuration to copy back and forth. Wiki Education then
  activates your registration (see below). Dynamic Registration is a paid Canvas
  add-on, so not every institution has it.
- **Manual install (fallback):** if you don't have Dynamic Registration, you
  configure the key yourself and Wiki Education completes one step on its end.

### Path A — Dynamic Registration (recommended)

1. In Canvas, go to **Admin → Developer Keys → + Developer Key → + LTI
   Registration**. Paste Wiki Education's registration URL —
   `https://wikiedu.ltiaas.com/lti/register` — and click **Continue**. Canvas and
   the Dashboard exchange the configuration automatically (endpoints, scopes, and
   placements); review the summary and click **Enable & Close**.
2. In the **Developer Keys** list, set the key's **State** to **ON** and copy the
   **Client ID** from the **Details** column.
3. Install it: **Admin → Settings → Apps → View App Configurations → + App**, set
   **Configuration Type** to **By Client ID**, paste the Client ID, and
   **Install**.

Your Canvas is now registered with the Dashboard automatically — there's no
configuration to send back. **Wiki Education reviews and activates each new
institution's registration** before launches work, so let them know you've
registered [PLACEHOLDER - contact / request form]; the tool starts working once
they activate it.

### Path B — Manual install (if Dynamic Registration isn't available)

1. Go to **Admin → Developer Keys → + Developer Key → + LTI Key**. Enter the
   configuration Wiki Education provides, using the **Method** they specify
   (**Enter URL** or **Paste JSON**). **Save**, set the **State** to **ON**, and
   copy the **Client ID** from the **Details** column.
2. Install it: **Admin → Settings → Apps → View App Configurations → + App**, set
   **Configuration Type** to **By Client ID**, paste the Client ID, and
   **Install**.
3. **Finish the registration.** On the installed app under **Settings → Apps**,
   open its settings (the gear/cog icon) and copy the **Deployment ID**. Send your
   **Client ID**, **Deployment ID**, and Canvas site URL to Wiki Education
   [PLACEHOLDER - contact / request form] so they can register your Canvas in
   LTIAAS. Launches will not succeed until this step is done.

### Choose how it appears

For either path, decide whether the course-navigation link shows up automatically:

- **Off by default (recommended):** instructors enable it per course under
  **Settings → Navigation**.
- **On by default:** it appears in every course's navigation.

## Enabling it for a course (the instructor)

Once the tool is installed, the requesting instructor:

1. Opens their course's **Settings → Navigation**, enables **Wiki Education
   Dashboard** (if it's off by default), and saves.
2. Clicks the new navigation link to launch the Dashboard, and links the Canvas
   course to their Wiki Education course.

From then on, their students launch the Dashboard from Canvas, and their progress
flows back to the gradebook.

## Troubleshooting

- **The link doesn't appear in a course.** If you installed it opt-in, the
  instructor needs to enable it under **Settings → Navigation** (and click Save).
  Confirm the app is listed under **Settings → Apps**.
- **Launching shows an error right after install.** The tool may not be active
  yet. On Path A, confirm Wiki Education has activated your registration; on Path
  B, confirm you sent the Client ID and Deployment ID to Wiki Education and they've
  acknowledged it.
- **"Refused to connect" inside the Canvas frame.** [PLACEHOLDER - Wiki Education
  to confirm the expected first-launch behavior (the Dashboard opens in a new tab
  for sign-in) and any known browser third-party-cookie caveats.]
- **Grades or the roster aren't syncing.** [PLACEHOLDER - Wiki Education to
  describe sync timing and how to confirm or trigger a sync.]

For anything else, contact Wiki Education (below).

## Getting help

[PLACEHOLDER - Wiki Education support contact (email / help URL) for admins.]
