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
third-party LTI service. Installing it follows the standard Canvas path for any
LTI 1.3 tool, and the steps below use Canvas's own labels so you can follow along
one-to-one in the admin interface.

There is also a reduced **LTI 1.1** version, for instructors whose institution
cannot install the 1.3 tool. It is not an institution-wide install: an instructor
adds it inside their own course, and there is nothing for an administrator to
install, approve, or configure. See
[Choosing between LTI 1.3 and LTI 1.1](#choosing-between-lti-13-and-lti-11).

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
  instructor imports the Wikipedia assignments, and Canvas creates a gradebook
  column for each. Canvas creates them unpublished, so publishing them is part of
  the flow (see [Enabling it for a course](#enabling-it-for-a-course-the-instructor)).

The LTI 1.1 version provides the first of these only: the course-navigation link,
with account connection and automatic enrollment. It has no roster sync, no
gradebook passback, and no assignment import.

## Choosing between LTI 1.3 and LTI 1.1

The two versions are installed by different people, in different places.

**LTI 1.3 is the institutional install**, and the one to use if you can. A Canvas
administrator installs it once on the root account and it becomes available to
every course. It is the full integration, it is the current LTI standard, and it
is the version Wiki Education develops against. The rest of this guide covers it.

**LTI 1.1 is a single-course install**, done by the instructor, in limited beta
and offered on request. There is no institution-wide version of it. The
instructor adds the tool inside their own course's Settings, using a consumer key
and shared secret issued for that one course; nothing is installed on your
account. The steps, with screenshots, are on the
[instructor install page](/lti/guide/instructors).

The 1.1 tool is a deliberately reduced, launch-only integration: students and
instructors reach the Dashboard from Canvas and students are enrolled
automatically, but nothing flows back to Canvas. Instructors grade from the
Dashboard, the way courses that don't use Canvas already do. Three things to
weigh:

- LTI 1.1 is the deprecated protocol. 1EdTech ended support for it in June 2022
  and formally deprecated its security model, which rests on a shared secret
  rather than the per-institution signed registration LTI 1.3 uses. Each of the
  Dashboard's 1.1 secrets covers one course rather than an institution, and stops
  working anywhere except the Canvas that first uses it.
- Under LTI 1.1 the Dashboard receives *less* data than under 1.3 (see
  [What data is shared](#before-you-install-review-and-approvals)) — there is no
  roster service — so if data sharing is the concern, 1.1 does not add to it.
- No third-party service sits in the 1.1 launch path. LTI 1.3 launches are
  fronted by [LTIAAS](https://ltiaas.com); the Dashboard verifies 1.1 launches
  itself.

| | LTI 1.3 | LTI 1.1 |
|---|---|---|
| Who installs it | A Canvas administrator | The course's instructor |
| Where it's installed | The root account, for every course | One course, in its own Settings |
| Course-navigation link, account connection, automatic enrollment | Yes | Yes |
| In-Canvas course overview for students and instructors | Yes | Yes |
| Roster sync (NRPS) | Yes | No |
| Assignment import (Deep Linking) | Yes | No |
| Gradebook passback (AGS) | Yes | No |
| Canvas requirements | Dynamic Registration (a paid add-on) | The course-level "LTI - add" permission, on by default |
| Third-party service in the launch path | LTIAAS | None |
| Credentials | None to manage — Canvas and the Dashboard exchange them | A key and secret the instructor generates, good for one course |

You can move from 1.1 to 1.3 later. Install the 1.3 tool following its steps
below, then [tell us](#getting-help) before any instructor removes the 1.1 tool
from their course: courses already linked through the 1.1 tool have to be moved to
the new install by Wiki Education, because a Dashboard course can be linked to
only one Canvas tool at a time.

## Who installs it, and where

This is about the **LTI 1.3** tool. The 1.1 tool is added by an instructor inside
a single course and is never installed on an account.

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
  each student is that student's Canvas ID, their role in the course, and their
  enrollment status in the course (active, inactive, or deleted). Where
  Canvas is set to share more, the Dashboard neither uses nor stores the
  additional fields. A student's identity comes from the Wikipedia account they
  connect on the Dashboard, not from Canvas. The Dashboard sends scores back to
  your gradebook; links to a student's work are shown in the Dashboard's own
  view inside Canvas, not written into your gradebook.

  Under **LTI 1.1** the same posture applies with less data: the tool is
  installed at the Anonymous privacy level, and because there is no roster
  service the Dashboard receives only the Canvas ID and course role of each
  person who actually opens the tool — nothing about students who never do, and
  no enrollment status. Nothing is written back to Canvas.

## What you'll need

For the **LTI 1.3** tool:

- Canvas **root-account administrator** access.
- Canvas's **Dynamic Registration** feature (a paid Canvas add-on). If your
  Canvas doesn't have it, contact Wiki Education (see Getting help); your
  instructors can use the LTI 1.1 tool in their own courses in the meantime.
- Wiki Education's registration URL:
  `https://wikiedu.ltiaas.com/lti/register?privacyLevel=anonymous`.
- About 15 minutes.

The **LTI 1.1** tool needs nothing from an administrator.

## Installation

These steps install the **LTI 1.3** tool on your account. For the 1.1 tool, see
the [instructor install page](/lti/guide/instructors) instead.

### Installing the LTI 1.3 tool

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
   **wikiedu.org**, and its logo.
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

#### What the LTI 1.3 tool adds to Canvas

The registration adds three placements — three surfaces where the Dashboard
appears:

| Placement | Where it shows up | What it's for |
|---|---|---|
| Course navigation | A **wikiedu.org** item in a course's left-hand nav | Entry point for setting up the Wiki Education Dashboard integration |
| Modules index menu | The **⋮** menu on a course's Modules page | Importing the Wikipedia assignments from the Dashboard Timeline |
| Assignment view | Inside each imported Wikipedia assignment | Details of each Dashboard assignment |

### The LTI 1.1 tool

There is no account-level install for the LTI 1.1 tool, and nothing in it for an
administrator to do. The instructor adds it inside their own course, under
**Settings → Apps → + App**, with the **By URL** configuration type and a consumer
key and shared secret issued for that one course. The steps, with screenshots,
are on the [instructor install page](/lti/guide/instructors) — send that link to
any instructor who asks.

Two things an administrator may need to know:

- **The course-level "LTI - add" permission** governs whether instructors can add
  apps to their own courses. It is on by default for teachers, TAs, and
  designers. Where an institution has turned it off, instructors cannot install
  the 1.1 tool at all, and the LTI 1.3 tool above is the way to give them the
  integration.
- **It adds one placement** — the **wikiedu.org** course-navigation item — in that
  one course. There is no Modules import and no assignment view, because the 1.1
  tool creates no assignments.

## Enabling it for a course (the instructor)

### With the LTI 1.3 tool

Once the app is available in their course, the instructor:

1. Clicks the **wikiedu.org** navigation link to launch the Dashboard, and links
   the Canvas course to their Wiki Education course.
2. On the course's **Modules** page, opens the **⋮** menu and chooses
   **wikiedu.org** to import the Wikipedia assignments and their gradebook
   columns.
3. Publishes the imported assignments and the module holding them. Canvas creates
   both **unpublished**, and students cannot see or open an unpublished
   assignment.

From then on, their students launch the Dashboard from Canvas, and their progress
flows back to the gradebook.

### With the LTI 1.1 tool

Installing and enabling are one job here, and the instructor does both. The
[instructor install page](/lti/guide/instructors) covers it. In short:

1. The instructor clicks the **wikiedu.org** navigation link, connects their
   Wikipedia account in the new tab that opens, and links the Canvas course to
   their Wiki Education course. That is the whole setup: there are no
   assignments to import.
2. Each student clicks the same **wikiedu.org** link, connects their Wikipedia
   account, and is enrolled in the Dashboard course automatically.

After that, the **wikiedu.org** tab shows each student their next step, articles,
trainings, and exercises, and shows the instructor how many students have
connected, with links out to the full Dashboard. Grading is done on the
Dashboard; nothing is written to the Canvas gradebook.

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

For the LTI 1.1 tool, the troubleshooting an instructor needs is on the
[instructor install page](/lti/guide/instructors). One item is an
administrator's to answer:

- **An instructor reports no + App button, or no Apps tab, in their course.**
  The course-level "LTI - add" permission is off for their role. Turn it on, or
  install the LTI 1.3 tool for the account instead.

For anything else, contact Wiki Education (below).

## Getting help

For support, contact sage at wikiedu.org.
