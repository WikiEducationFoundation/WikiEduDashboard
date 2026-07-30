# Adding the Wiki Education Dashboard to your Canvas

> **About this guide.** It documents a Canvas integration that is new, and both the
> integration and this guide are still changing. Most of the guide was drafted by
> Claude Code, an AI coding assistant, working from the integration's source and
> from walkthroughs of a real Canvas install; Wiki Education staff direct and
> review it, and the installation steps have been followed end to end against a
> live Canvas. If something here doesn't match what you see, trust Canvas and
> [tell us](#getting-help).

This guide is for **Canvas administrators** at colleges and universities whose
instructors use the [Wiki Education Dashboard](https://dashboard.wikiedu.org) to
run Wikipedia writing assignments. It covers evaluating, installing, and enabling
the Dashboard's Canvas integration.

The integration is an **LTI 1.3** tool, fronted by [LTIAAS](https://ltiaas.com), a
third-party LTI service. Installing it follows the standard Canvas path for any LTI
1.3 tool. The steps below use Canvas's own labels so you can follow along
one-to-one in the admin interface.

## What the integration does

Once installed, the Wiki Education Dashboard becomes an LTI tool in your Canvas,
listed as **wikiedu.org** in your developer keys, your apps, and course
navigation:

- **Course-navigation link** — instructors and students open the Dashboard from a
  **wikiedu.org** link in the course's left-hand navigation. The first time, they
  connect their Wikipedia account in a new tab; after that the tool shows their
  course and progress in place.
- **Roster sync (NRPS)** — students who launch the tool are added to the
  instructor's Dashboard course automatically.
- **Gradebook passback (AGS)** — the training modules and exercises students
  complete on the Dashboard report back as scores in your Canvas gradebook.
- **Assignment import (Deep Linking)** — from a course's Modules page, an
  instructor imports the Wikipedia assignments in one step, and Canvas creates a
  gradebook column for each.

## Who installs it, and where

Install the integration on your Canvas instance's **root (institution) account**,
as a Canvas administrator — the same place you manage other institution-wide LTI
tools. It does **not** require Site Admin access (on Instructure-hosted Canvas you
won't have that anyway). You can also install on a **sub-account** to limit the
tool to one division.

Installing on the root account makes the tool *available* everywhere, and its
course-navigation link appears in every course's navigation.

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
  course navigation, the Modules index menu, and the assignment view.
- **What data is shared:** The integration is designed around Canvas's
  Anonymized data-sharing model: the only Canvas data it requires or saves for
  each student is that student's Canvas ID and their role in the course. Where
  Canvas is set to share more, the Dashboard neither uses nor stores the
  additional fields. A student's identity comes from the Wikipedia account they
  connect on the Dashboard, not from Canvas. The Dashboard sends scores back to
  your gradebook; links to a student's work are shown in the Dashboard's own
  view inside Canvas, not written into your gradebook.

## What you'll need

- Canvas **root-account administrator** access.
- Canvas's **Dynamic Registration** feature (a paid Canvas add-on). If your
  Canvas doesn't have it, contact Wiki Education (see Getting help).
- Wiki Education's registration URL:
  `https://wikiedu.ltiaas.com/lti/register?privacyLevel=anonymous`.
- About 15 minutes.

## Installation

Installation uses Canvas's **Dynamic Registration**: you paste one URL and Canvas
and the Dashboard configure everything automatically — endpoints, scopes, and
placements, and registering your Canvas with the tool — with no configuration to
copy back and forth. Wiki Education then activates your registration (see below).

Wiki Education's registration URL:

    https://wikiedu.ltiaas.com/lti/register?privacyLevel=anonymous

Registering, installing, and making the app available are three separate steps.
Canvas reports success after each one, so it's easy to stop early and end up
with an app that exists but appears nowhere.

1. **Register.** In Canvas, go to
   **Admin → Developer Keys → + Developer Key → + LTI Registration**.
   Paste Wiki Education's registration URL and click
   **Continue**. Canvas and the Dashboard exchange the configuration
   automatically (endpoints, scopes, and placements). The registration dialog
   also shows optional **Title** and **Icon URL** fields for each placement.
   Leave them blank: each placement is then labeled with the tool's own name,
   **Wiki Education Dashboard**, and its logo.
   Review the summary and click **Enable & Close**.
2. **Turn the key on.** In the **Developer Keys** list, set the key's **State**
   to **ON**.
3. **Install it.** In that same row's **Details** column, click **View in
   Canvas Apps**. The app appears there as installed in your account.
4. **Make it available.** Open the installation and make it available — for the
   whole account, or for particular sub-accounts and courses using **Add
   Exception**, whichever suits your institution. Until you do, the app is
   present but inert: no course can see it.

Your Canvas is now registered with the Dashboard automatically — there's no
configuration to send back. **Wiki Education reviews and activates each new
institution's registration** before launches work, so let them know you've
registered by emailing sage at wikiedu.org; the tool starts working once
they activate it.

### What gets added to Canvas

The registration adds three placements — three surfaces where the Dashboard
appears:

| Placement | Where it shows up | What it's for |
|---|---|---|
| Course navigation | A **wikiedu.org** item in a course's left-hand nav | Entry point for setting up the Wiki Education Dashboard integration |
| Modules index menu | The **⋮** menu on a course's Modules page | Importing the Wikipedia assignments from the Dashboard Timeline |
| Assignment view | Inside each imported Wikipedia assignment | Details of each Dashboard assignment |

## Enabling it for a course (the instructor)

Once the app is available in their course, the instructor:

1. Clicks the **wikiedu.org** navigation link to launch the Dashboard, and links
   the Canvas course to their Wiki Education course.
2. On the course's **Modules** page, opens the **⋮** menu and chooses
   **wikiedu.org** to import the Wikipedia assignments and their gradebook
   columns.

From then on, their students launch the Dashboard from Canvas, and their progress
flows back to the gradebook.

## Troubleshooting

- **Nothing appears in any course after registering.** Registering, turning the
  key on, installing, and making it available are separate steps — check each
  in turn (see [Installation](#installation)). An app that is registered but
  not yet available is invisible to every course, with no error shown.
- **The key looks ON but the app won't install.** Toggle the key's **State**
  off and back on in **Developer Keys**, then retry. Canvas can display the key
  as enabled when it isn't, and the install has nothing to attach to.
- **The link doesn't appear in a course.** Confirm the app is available to that
  course — if you are using exceptions, confirm that course has one. An instructor
  can also have hidden the item under **Settings → Navigation**, in which case they
  re-enable it there.
- **Launching shows an error right after install.** The tool may not be active
  yet — confirm Wiki Education has activated your registration.

For anything else, contact Wiki Education (below).

## Getting help

For support, contact sage at wikiedu.org.
