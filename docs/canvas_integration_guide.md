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
1.3 tool — create a developer key, install it by its Client ID, and register your
Canvas with the tool. The steps below use Canvas's own labels so you can follow
along one-to-one in the admin interface.

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

You choose this when you configure the developer key (below), and can change it
later.

## Before you install: review and approvals

Most institutions review a tool's accessibility and data handling first:

- **Accessibility (VPAT):**
  [dashboard.wikiedu.org/accessibility](https://dashboard.wikiedu.org/accessibility)
  — VPAT 2.5 (WCAG edition), evaluated against WCAG 2.1 A and AA.
- **Security & privacy (HECVAT):**
  [dashboard.wikiedu.org/hecvat](https://dashboard.wikiedu.org/hecvat).
- **What the tool requests from Canvas:** the LTI key asks for read access to a
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
- The Dashboard's **LTI configuration**, and a registration with Wiki Education
  (step 1).
- About 15 minutes.

## Installation

One wrinkle to know up front: because the tool is fronted by LTIAAS, your Canvas
has to be **registered** with it once — and that registration needs the **Client
ID** Canvas generates in step 2. So you'll start the registration (step 1), create
the key and copy its Client ID (step 2), and hand the Client ID and Deployment ID
back to finish (step 4). Steps 1 and 4 are the two halves of that handshake.

### 1. Request the integration from Wiki Education

[PLACEHOLDER / CONFIRM - the onboarding hand-off. Each institution's Canvas is
registered with the Dashboard's LTIAAS tenant once. Confirm whether the admin
self-registers in the LTIAAS portal or Wiki Education registers the platform (given
the Canvas issuer and the Client ID from step 2), and give the admin a contact or
request form to start that here.] Wiki Education provides the **LTI configuration**
you enter in step 2.

### 2. Create the LTI 1.3 developer key

In Canvas: **Admin → Developer Keys → + Developer Key → + LTI Key.**

1. Enter the configuration Wiki Education provided, using the **Method** they
   specify — usually **Enter URL** (paste a configuration URL) or **Paste JSON**.
   That fills in the redirect URIs, target link, OpenID Connect URL, public JWK
   URL, scopes, and placements for you.
2. **Save**, then set the key's **State** to **ON** in the Developer Keys list.
3. Copy the **Client ID** — the numeric value shown in the **Details** column (not
   the "Show Key" secret). You need it in step 3, and Wiki Education needs it to
   finish the registration.

### 3. Install the app by Client ID

Go to **Admin → Settings → Apps → View App Configurations → + App.** Set
**Configuration Type** to **By Client ID**, paste the Client ID from step 2, click
**Submit**, then **Install** in the confirmation dialog. (Do this on the root
account, or on a sub-account to scope the tool there.) The Wiki Education Dashboard
is now installed.

### 4. Finish the registration

On the installed app under **Settings → Apps**, open its settings (the gear/cog
icon) and copy the **Deployment ID**. Send your **Client ID**, **Deployment ID**,
and Canvas site URL back to Wiki Education [PLACEHOLDER - via the contact/form from
step 1] to complete the LTIAAS registration. Launches will not succeed until this
is done.

### 5. Choose how it appears

Decide whether the course-navigation link shows up automatically (this can also be
set by the configuration in step 2):

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
- **Launching shows an error right after install.** The LTIAAS registration (step
  4) may not be complete — confirm the Client ID and Deployment ID were sent to,
  and acknowledged by, Wiki Education.
- **"Refused to connect" inside the Canvas frame.** [PLACEHOLDER - Wiki Education
  to confirm the expected first-launch behavior (the Dashboard opens in a new tab
  for sign-in) and any known browser third-party-cookie caveats.]
- **Grades or the roster aren't syncing.** [PLACEHOLDER - Wiki Education to
  describe sync timing and how to confirm or trigger a sync.]

For anything else, contact Wiki Education (below).

## Getting help

[PLACEHOLDER - Wiki Education support contact (email / help URL) for admins.]
