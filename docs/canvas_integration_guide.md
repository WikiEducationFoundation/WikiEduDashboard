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

> **Instructors:** you may not need an administrator at all. Canvas lets a
> teacher add an LTI 1.1 app to their own course, and the Dashboard's LTI 1.1
> version installs that way in a few minutes — see the short, illustrated
> [instructor install page](/lti/guide/instructors).

The integration is an **LTI 1.3** tool, fronted by [LTIAAS](https://ltiaas.com), a
third-party LTI service. Installing it follows the standard Canvas path for any LTI
1.3 tool. For institutions that cannot install LTI 1.3 tools there is also an
**LTI 1.1** version with a smaller feature set — see
[Choosing between LTI 1.3 and LTI 1.1](#choosing-between-lti-13-and-lti-11). The
steps below use Canvas's own labels so you can follow along one-to-one in the
admin interface.

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

Install the **LTI 1.3** tool if you can. It is the full integration, it is the
current LTI standard, and it is the version Wiki Education develops against.

The **LTI 1.1** tool exists for institutions whose review process does not yet
admit LTI 1.3 applications. It is a deliberately reduced, launch-only
integration: students and instructors reach the Dashboard from Canvas and
students are enrolled automatically, but nothing flows back to Canvas.
Instructors grade from the Dashboard, the way courses that don't use Canvas
already do. Two things to weigh:

- LTI 1.1 is the deprecated protocol. 1EdTech ended support for it in June 2022
  and formally deprecated its security model, which rests on a shared secret
  rather than the per-institution signed registration LTI 1.3 uses.
- Under LTI 1.1 the Dashboard receives *less* data than under 1.3 (see
  [What data is shared](#before-you-install-review-and-approvals)) — there is no
  roster service — so if data sharing is the concern, 1.1 does not add to it.

| | LTI 1.3 | LTI 1.1 |
|---|---|---|
| Course-navigation link, account connection, automatic enrollment | Yes | Yes |
| In-Canvas course overview for students and instructors | Yes | Yes |
| Roster sync (NRPS) | Yes | No |
| Assignment import (Deep Linking) | Yes | No |
| Gradebook passback (AGS) | Yes | No |
| Canvas requirements | Dynamic Registration (a paid add-on) | None beyond admin access |
| Credentials | None to manage — Canvas and the Dashboard exchange them | A consumer key and shared secret from Wiki Education |

You can move from 1.1 to 1.3 later. Install the 1.3 tool following its steps
below, then [tell us](#getting-help) before removing the 1.1 tool: courses already
linked through the 1.1 tool have to be moved to the new install by Wiki Education,
because a Dashboard course can be linked to only one Canvas tool at a time.

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
  Canvas doesn't have it, contact Wiki Education (see Getting help), or use the
  LTI 1.1 tool.
- Wiki Education's registration URL:
  `https://wikiedu.ltiaas.com/lti/register?privacyLevel=anonymous`.
- About 15 minutes.

For the **LTI 1.1** tool:

- Canvas **root-account administrator** access.
- A **consumer key and shared secret** from Wiki Education — email
  sage at wikiedu.org and say which institution the install is for. The same
  key and secret are shared by every institution using the 1.1 tool, so treat
  them as you would any other tool secret.
- Wiki Education's configuration URL:
  `https://dashboard.wikiedu.org/lti/legacy/config.xml`.
- About 10 minutes.

## Installation

Follow one of the two sections below, not both.

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

### Installing the LTI 1.1 tool

The LTI 1.1 tool is installed the way Canvas installs any legacy external app:
from an XML configuration URL plus a consumer key and shared secret. Use the
**By URL** configuration type, not **Manual Entry** — a manually entered tool
has no course-navigation placement, so nobody would be able to find it.

The same form exists inside each course's own Settings, where an instructor
can install the tool for that one course without an administrator (unless the
institution has turned off the "LTI - add" course permission). Those steps,
with screenshots, are on the [instructor install page](/lti/guide/instructors).
The account-level install below makes the tool available in every course.

1. **Get the credentials.** Email sage at wikiedu.org for the LTI 1.1 consumer
   key and shared secret, naming your institution.
2. **Open the account's apps.** In Canvas, go to
   **Admin → (your root account) → Settings → Apps**, then click
   **View App Configurations** and **+ App**.
3. **Configure it.** In the dialog:
   - **Configuration Type:** By URL
   - **Name:** wikiedu.org
   - **Consumer Key** and **Shared Secret:** the values from step 1
   - **Config URL:** `https://dashboard.wikiedu.org/lti/legacy/config.xml`

   Click **Submit**. Canvas fetches the configuration, which sets the launch URL,
   the Anonymous privacy level, and the course-navigation placement. (If your
   Canvas cannot fetch external URLs, choose **Paste XML** instead, open the
   configuration URL in a browser, and paste its contents.)
4. **Check a course.** Open any course in the account: a **wikiedu.org** item
   appears in its left-hand navigation. It is enabled by default in every
   course; an instructor who doesn't want it can hide it under
   **Settings → Navigation**.
5. **Tell Wiki Education** you've installed it (sage at wikiedu.org), so they
   can confirm launches are arriving from your Canvas.

To limit the tool to one division, do the same on a **sub-account** instead of
the root account.

#### What the LTI 1.1 tool adds to Canvas

One placement: the **wikiedu.org** course-navigation item. There is no Modules
import and no assignment view, because the 1.1 tool creates no assignments.

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

For the LTI 1.1 tool:

- **No wikiedu.org item appears in courses.** The tool was probably added with
  **Manual Entry**, which has no course-navigation placement. Delete it from
  **Settings → Apps** and add it again with **By URL** and the configuration URL
  (see [Installing the LTI 1.1 tool](#installing-the-lti-11-tool)).
- **Clicking the item shows an error page from ltiaas.com** (for example
  "Failed OAuth signature verification"). The consumer key or shared secret was
  entered incorrectly. Open the app's settings (the gear icon next to it under
  **Settings → Apps**) and re-enter both, or delete and reinstall it.
- **The item shows only "Unavailable".** It was opened from an assignment or
  module import dialog. The 1.1 tool has no assignment import; use the
  course-navigation item.

For anything else, contact Wiki Education (below).

## Getting help

For support, contact sage at wikiedu.org.
