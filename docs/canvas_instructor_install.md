# Add the Wiki Education Dashboard to your Canvas course

> **About this page.** It was drafted by Claude Code, an AI coding assistant, from
> a walkthrough of a real Canvas course; Wiki Education staff direct and review it.
> The screenshots are from that walkthrough. If Canvas looks different for you,
> trust Canvas and [tell us](#if-something-doesnt-work). Canvas administrators:
> the [full installation guide](/lti/guide) covers institution-wide installs and
> the LTI 1.3 version.

This page is for **instructors**. If your Canvas lets you add apps to your own
course (most do), you can add the Dashboard yourself in about five minutes, with
no administrator involved.

What you get: a **wikiedu.org** link in your course navigation. You use it to
link the Canvas course to your Wiki Education course; your students use it to
connect their Wikipedia accounts and are enrolled in your Dashboard course
automatically. This is the Dashboard's **LTI 1.1** tool, which does not send
grades to the Canvas gradebook or read your roster — you grade from the
Dashboard, as usual.

## You'll need

- Your course on the [Wiki Education Dashboard](https://dashboard.wikiedu.org),
  created and approved.
- The **consumer key** and **shared secret** — email sage at wikiedu.org, naming
  your institution and course. Keep them private, like a password.
- This configuration URL, to paste in step 3:
  `https://dashboard.wikiedu.org/lti/legacy/config.xml`

## Steps

### 1. Open your course's Settings, then the Apps tab

In your Canvas course, click **Settings** at the bottom of the course
navigation, then the **Apps** tab (not "Apps (New)").

![Course Settings with the Apps tab](/assets/images/canvas_guide/instructor-install-1-settings-apps-tab.png)

### 2. Click + App

If you see **View App Configurations** first, click that, then **+ App**.

![The External Apps page with the + App button](/assets/images/canvas_guide/instructor-install-2-external-apps.png)

### 3. Fill in the Add App form and submit

- **Configuration Type:** By URL
- **Name:** wikiedu.org
- **Consumer Key** and **Shared Secret:** the values from Wiki Education
- **Config URL:** `https://dashboard.wikiedu.org/lti/legacy/config.xml`

Click **Submit**.

![The Add App form filled in with By URL](/assets/images/canvas_guide/instructor-install-3-add-app-by-url.png)

### 4. Check that it's there

**wikiedu.org** now appears in your External Apps list and in your course
navigation.

![wikiedu.org in the External Apps list and the course navigation](/assets/images/canvas_guide/instructor-install-4-app-added.png)

### 5. Link your course

Click **wikiedu.org** in the course navigation, then **Open the Wiki Education
Dashboard**. In the new tab, connect your Wikipedia account and choose your
Dashboard course. That's the whole setup.

From now on, students who click **wikiedu.org** connect their Wikipedia accounts
the same way and are enrolled automatically; the tab then shows each of them
their next steps, articles, trainings, and exercises.

![The first launch inside Canvas](/assets/images/canvas_guide/instructor-install-5-first-launch.png)

## If something doesn't work

- **There is no + App button, or the Apps tab is missing.** Your institution
  has turned off adding apps at the course level. Ask your Canvas administrator
  to install it — send them the [installation guide](/lti/guide).
- **Canvas won't save the app, or says it already exists.** A tool with the
  same address is already installed higher up in your Canvas — probably by an
  administrator — so it should already be in your course navigation. If it
  isn't, check **Settings → Navigation**.
- **Clicking wikiedu.org shows an error page from ltiaas.com** (for example
  "Failed OAuth signature verification"). The key or secret was mistyped. In
  **Settings → Apps**, click the gear next to **wikiedu.org**, choose **Edit**,
  and re-enter both.
- **The link says the course is not linked yet, for students.** Do step 5 first
  — students can't link the course themselves.

For anything else, email sage at wikiedu.org.
