> **Draft — not yet approved for publication.** This first pass was drafted by
> Claude Code from Wiki Education's internal setup notes; the wording is
> provisional and every placeholder below is pending Wiki Education's review.
> [PLACEHOLDER - Wiki Education to review, edit, and finalize this guide, and
> remove this banner, before it goes live.]

# Adding the Wiki Education Dashboard to your Canvas

This guide is for **Canvas administrators** at colleges and universities whose
instructors use the [Wiki Education Dashboard](https://dashboard.wikiedu.org) to
run Wikipedia writing assignments. It covers evaluating, installing, and enabling
the Dashboard's Canvas integration.

## What the integration does

Once it is installed, the Wiki Education Dashboard becomes an LTI tool in your
Canvas:

- **Course-navigation link** — instructors and students open the Dashboard from a
  link in the course's left-hand navigation, already signed in.
- **Roster sync** — students who launch the tool are added to the instructor's
  Dashboard course automatically.
- **Gradebook passback** — the training modules and exercises students complete on
  the Dashboard report back as scores in your Canvas gradebook.
- **Assignment integration** — instructors can add specific Dashboard exercises as
  Canvas assignments.

The tool uses the LTI 1.3 standard and is fronted by [LTIAAS](https://ltiaas.com),
a third-party LTI service.

## Who installs it, and where

The integration is installed on your Canvas instance's **root (institution)
account**, by a Canvas administrator — the same place you manage other
institution-wide LTI tools. It does **not** require Site Admin access.

Installing on the root account makes the tool available to every course, but you
can leave it switched off by default so it appears only in the courses that opt in
(recommended for a first rollout — see step 4 below).

## Before you install: review and approvals

Most institutions review a new tool's accessibility and data handling before
installing. For the Dashboard:

- **Accessibility (VPAT):** the Dashboard's accessibility conformance report is
  published at
  [dashboard.wikiedu.org/accessibility](https://dashboard.wikiedu.org/accessibility)
  (VPAT 2.5, WCAG edition; evaluated against WCAG 2.1 A and AA).
- **Security & privacy (HECVAT):** [PLACEHOLDER - link to, or current status of,
  the Dashboard's HECVAT (Higher Education Community Vendor Assessment Toolkit).]
- **What data is shared:** when a student launches the tool, Canvas shares their
  name and course-roster membership with the Dashboard (through LTIAAS) so they can
  be added to the course; the Dashboard sends scores, and links to the students'
  work, back to your gradebook. [PLACEHOLDER - Wiki Education to confirm and expand
  this data-sharing summary so it matches the HECVAT and the privacy policy.]

## What you'll need

- Canvas **root-account administrator** access.
- The Dashboard's **LTI configuration** from Wiki Education. [PLACEHOLDER - how the
  admin obtains this: a JSON configuration URL, a paste-in configuration, or a
  contact who provides it.]
- About 15 minutes.

## Installation

### 1. Get in touch with Wiki Education

[PLACEHOLDER / CONFIRM - the onboarding hand-off. Each institution's Canvas has to
be registered with the Dashboard's LTIAAS tenant once. Confirm whether the admin
self-registers in the LTIAAS portal, or Wiki Education registers the institution
given its Canvas issuer and the Client ID from step 2 — and give the admin a
contact or request form to start that here.]

### 2. Create a developer key

In Canvas, go to **Admin → Developer Keys → + Developer Key → + LTI Key**. Enter
the Dashboard's LTI configuration provided by Wiki Education, save it, and switch
the key's state to **ON**. Copy the **Client ID** that Canvas generates — you need
it in the next step, and Wiki Education needs it to finish registration.

### 3. Install the app

Go to **Admin → Apps → + App**, choose **By Client ID**, paste the Client ID from
step 2, and install. The Wiki Education Dashboard is now available across your
institution.

### 4. Choose how it appears

Decide whether the course-navigation link shows up on its own:

- **Off by default (recommended to start):** the tool is installed but hidden;
  each instructor turns it on for their own course under **Settings → Navigation**.
  Courses that don't use it are unaffected.
- **On by default:** the link appears in every course's navigation.

## Enabling it for a course

Once the tool is installed, the requesting instructor:

1. Opens their course's **Settings → Navigation** and enables **Wiki Education
   Dashboard** (if it is off by default).
2. Clicks the new navigation link to launch the Dashboard, and links the Canvas
   course to their Wiki Education course.

From then on, their students launch the Dashboard from Canvas, and their progress
flows back to the gradebook.

## Getting help

[PLACEHOLDER - Wiki Education support contact (email / help URL) for admins who run
into problems during installation.]
