[Back to README](../README.md)

There is ongoing work to integrate the Dashboard with the widely-used **[Canvas LMS](https://community.instructure.com/en/kb/articles/662716-what-is-canvas)**. This integration is made possible using the **[IMS LTI Standard](https://www.1edtech.org/standards/lti)**.

The dashboard has integrated the third-party **[LTIAAS API](https://docs.ltiaas.com/guides/introduction)** (see [LTIAAS Integration PR](https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/6201)) and is configured on the LTIAAS portal allowing the codebase act as a LTI 1.3 compliant learning tool.

To use the tool, a Canvas admin installs the Dashboard's LTIAAS tool into their canvas environment / instance by [manual registration](https://docs.ltiaas.com/guides/lms/canvas#manual-registration).

## Basic LTI Launch
Once a canvas dev environment is running locally and the LTIAAS tool is installed in it, the integration is successful if a basic LTI launch can be completed:

1. User (student/admin/other role) logs into Canvas LMS
2. User clicks on the tool link (displayed as a course assignment or as configured in Canvas)
3. Canvas initiates login with LTIAAS using an OIDC flow; uses LTI protocol to confirm user identity (see: [LTI Launch Overview](https://developerdocs.instructure.com/services/canvas/external-tools/lti/file.lti_launch_overview))
4. If successful, LTIAAS redirects the user to the Dashboard's `/lti` route, which dispatches by role and placement (see the flows below)


## Table of Contents
- [Basic LTI Launch](#basic-lti-launch)
- [Ways to Run Canvas Locally](#ways-to-run-canvas-locally)
- [Running Canvas Locally using Docker and Apache](#running-canvas-locally-using-docker-and-apache)
   - [Setup Docker](#1-setup-docker)
   - [Setup Swapfile](#2-setup-swapfile)
   - [Install Canvas LMS](#3-install-canvas-lms)
   - [Set Docker Permissions](#4-set-docker-permissions)
   - [Run Initial Canvas Setup Script](#5-run-initial-canvas-setup-script)
- [Self hosting with a VPS](#self-hosting-with-a-vps)
   - [Configure Canvas](#6-configure-canvas)
   - [Install and configure Rich Content Editor API](#7-install-and-configure-rich-content-editor-api)
   - [Start Docker/Canvas on instance startup (optional)](#8-start-dockercanvas-on-instance-startup-optional)
   - [Configure Apache](#9-configure-apache)
- [Self hosting with a tunneling service](#self-hosting-by-exposing-localhost-through-a-tunneling-service)
   - [Configure Canvas](#6-configuring-canvas)
   - [Install and configure Rich Content Editor API](#7-installing-and-configuring-rich-content-editor-api)
   - [Start Docker/Canvas on instance startup (optional)](#8-starting-dockercanvas-on-instance-startup-optional)
   - [Configure Apache](#9-configuring-apache)
   - [Tunnel local Canvas](#10-tunneling-your-local-canvas)
- [Integrate the Dashboard into Canvas](#integrate-the-dashboard-into-canvas)
   - [Install the Dashboard's LTIAAS tool in your canvas environment](#install-the-dashboards-ltiaas-tool-in-your-canvas-environment)
   - [Test Launch](#test-launch)
      - [Change Issuer](#1-changing-the-iss-value-in-configsecurityyml-to-your-public-url)
      - [Change Domain](#2-changing-the-domain-in-configdomainyml-to-your-public-url)
- [Other Guides, References and Sources](#other-guides-references-and-sources)

## Ways to Run Canvas Locally
Canvas can be installed manually or using docker, along with a reverse proxy of choice and there are existing guides for each method:
- Using docker: 
   - [Using Docker and optionally Dory for Canvas Development by Instructure](https://github.com/instructure/canvas-lms/blob/master/doc/docker/developing_with_docker.md)
   - [Running Canvas LMS Locally using NGINX by UCFCDL](https://github.com/ucfcdl/Running-Canvas-LMS-Locally)

- Manual installation:
   - [Quick Start to build Canvas LMS locally by Instructure](https://github.com/instructure/canvas-lms/wiki/Quick-Start)
   - [How to Install Canvas on Ubuntu 22.04 using Apache by Linode](https://www.linode.com/docs/guides/install-canvas-lms-on-ubuntu-2204/)
   - [Self Host and Install Canvas LMS using Apache by eLearning evolve](https://elearningevolve.com/blog/install-canvas-lms/)

If you already have a working Dashboard dev environment set up, it is **recommended to use Apache** as the Dashboard uses it.

To complete a basic LTI launch, your canvas instance has to be reachable via the internet hence the need to self host. This can be done by acquiring a domain and using a VPS or simply exposing your localhost to the internet via tunneling services like ngrok, zrok, etc. 

The instructions below cover setup using docker in the two scenarios.

## Running Canvas Locally using Docker and Apache 
This setup is based on the following guide: **[Running Canvas LMS Locally using NGINX by UCFCDL](https://github.com/ucfcdl/Running-Canvas-LMS-Locally)**. It will be referred to as the parent guide.

The steps stated in the parent guide should be followed in the order listed below, taking note of the below recommendations:

### 1. Setup Docker
After installing docker, the 'Set Docker Permissions' step should be skipped until you have cloned canvas into a chosen directory and you are cd into that directory. This is to prevent giving docker access to every single file on your system if the commands are run in root.
### 2. Setup Swapfile
### 3. Install Canvas LMS
- Ideally do not clone canvas directly to `/home/user/` becauses if you encounter permissions issues with Apache, the suggested fixes might need you to give Apache access to your entire `home/` directory

- Check for the latest stable branch here: https://github.com/instructure/canvas-lms/tree/master , search 'stable/2026'
### 4. Set Docker Permissions
Can safely set permissions here since current directory should be the canvas directory
### 5. Run Initial Canvas Setup Script
- Dory is skipped here since Apache is to be used. Dory does not work if other processes are using port 80 and although there is an option to allow Dory kill and restart the systemd processes, the kill action disconnects you from the internet. It is also not as configurable as other reverse proxies.

- If the script fails during the initial run, and you try to DROP the database while running it again, you might get an error like: 
   ```
   > Checking for existing db... [DONE] 
   > An existing database was found. 
   Do you want to drop and create new or migrate existing? [DROP/migrate] DROP 
   > !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
   This script will destroy ALL EXISTING DATA if it continues If you want to migrate the existing database, cancel now 
   !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! 
   > About to run "bundle exec rake db:drop" 
   > Deleting db..... 
   [FAIL] /o\ Something went wrong. Check canvas-lms/log/docker_dev_setup.log for details. 
   Caused by: PG::ObjectInUse: ERROR: database "canvas_development" is being accessed by other users (PG::ObjectInUse) 
   DETAIL: There is 1 other session using the database. 
   /home/docker/.gem/3.4/gems/activerecord-8.0.3/lib/active_record/connection_adapters/postgresql/database_statements.rb:167:in 'PG::Connection#exec'
   ```
The fix is to do a fresh start to avoid leftover connections by running the command: `docker compose down -v` to stop and remove containers, networks and volumes. Note that once volumes are removed with `-v`, the data cannot be recovered.

At this stage, the instructions deviate based on whether you are using a VPS or not.

## Self hosting with a VPS
For steps with nothing extra stated, simply follow the instructions in the parent guide.
### 6. Configure Canvas
### 7. Install and configure Rich Content Editor API
- You can change the port from `3000` to  `3100` for example if another process / service / app is already using port `3000`

- Further configuration such as cloning and installing RCE standalone might be needed if the rich content editor is not fully functional in Canvas after following the stated steps. See the [official docs](https://github.com/instructure/canvas-rce-api/blob/master/README.md) for guidance.
### 8. Start Docker/Canvas on instance startup (optional)
### 9. Configure Apache 
At this point, skip the nginx section and follow the below instructions to configure Apache:

#### 1. Install Apache if not already installed
#### 2. Verify host port bindings are correct
   Run `docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"`. The results returned should be similar to below:
   ```
   NAMES                       IMAGE                        PORTS
   canvas-lms-web-1            canvas-lms-web               0.0.0.0:9100->80/tcp, [::]:9100->80/tcp
   canvas-lms-jobs-1           canvas-lms-jobs              80/tcp
   canvas-lms-webpack-1        canvas-lms-webpack           80/tcp
   canvas-lms-canvasrceapi-1   instructure/canvas-rce-api   0.0.0.0:3100->80/tcp, [::]:3100->80/tcp
   canvas-lms-redis-1          redis:alpine                 6379/tcp
   canvas-lms-postgres-1       canvas-lms-postgres          5432/tcp
   canvas-lms-mailcatcher-1    instructure/mailcatcher      1025/tcp, 8080/tcp
   ```
#### 3. In your `/etc/apache2/sites-available/` directory add a `canvas.conf` file:
```
<VirtualHost *:80>
    ServerName your-canvas-domain-here

    ProxyPreserveHost On
    ProxyRequests Off

    RequestHeader set X-Forwarded-Proto "https"

    ProxyTimeout 300
    Timeout 300
    ProxyIOBufferSize 1048576

    # RCE API service
    ProxyPass        /rce/   http://127.0.0.1:3100/
    ProxyPassReverse /rce/   http://127.0.0.1:3100/

    # Main Canvas app
    ProxyPass        /       http://127.0.0.1:9100/
    ProxyPassReverse /       http://127.0.0.1:9100/

    ErrorLog ${APACHE_LOG_DIR}/canvas_error.log
    CustomLog ${APACHE_LOG_DIR}/canvas_access.log common
</VirtualHost>
```
#### 4. Enable the site and restart Apache
```
sudo a2enmod proxy proxy_http ssl headers
sudo a2ensite canvas.conf
sudo apachectl configtest # Syntax OK expected
sudo systemctl restart apache2
```



## Self hosting by exposing localhost through a tunneling service
The default http://canvas.docker domain is used in this case. The instructions here differ from the parent guide in that no ssl is required and port numbers are changed to prevent conflict with other local applications that also use locahost.

### 6. Configuring Canvas
#### a.  `docker-compose.override.yml`: 
Here only the port is added, the `VIRTUAL_HOST` value is left as default:
   ```
   ...
    web:
    <<: *BASE
    ports:    # only thing added
      - "9100:80"
    environment:
      <<: *BASE-ENV
      VIRTUAL_HOST: .canvas.docker
   ...
   ```
#### b. `config/domain.yml`: No changes here for now
#### c. Session store : 
Simply copy the contents of `config/session_store.yml.example` to a new file `config\session_store.yml` by running `cp /config/session_store.yml.example config/session_store.yml`. Since https is not being used, no need to uncomment the `# secure: true`
#### d. `config/dynamic_settings.yml`: 
The default domain remains the same but we want rce to be accessible via the `/rce` path so modify the `app-host` value:
   ```
   development:
   config:
      canvas:
         ...
         rich-content-service:
            app-host: 'http://canvas.docker/rce'
         ...
   ```
#### e. Vault contents: 
Create a `vault_contents.yml` from the example one `cp /config/vault_contents.yml.example config/vault_contents.yml`. It is useful if you do not want to run vault with canvas and common in local dev envs.
#### f. Environmental Variables: 
Go to `.env` and add the RCE and mailcatcher services:
   ```
   COMPOSE_FILE=docker-compose.yml:docker-compose.override.yml:docker-compose/mailcatcher.override.yml:docker-compose/rce-api.override.yml # mailcatcher and RCE service added to base settings
   ```
### 7. Installing and configuring Rich Content Editor API
Go to `docker-compose/rce-api.override.yml` to change the domain and port used since the Dashboard uses port 3000:
```
services:
  web:
    links:
      - canvasrceapi

  canvasrceapi:
    image: instructure/canvas-rce-api
    ports:
      - "3100:80" # change here
    environment:
      VIRTUAL_HOST: canvas.docker
      VIRTUAL_PORT: 80
```

Save all files and restart the docker containers to apply the changes: `docker compose down` and `docker compose up -d`

### 8. Starting Docker/Canvas on instance startup (optional)
Follow instructions in parent guide

### 9. Configuring Apache
#### a. Install Apache if not already installed
#### b. Verify host port bindings are correct
   Run `docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}"`. The results returned should be similar to below:
   ```
   NAMES                       IMAGE                        PORTS
   canvas-lms-web-1            canvas-lms-web               0.0.0.0:9100->80/tcp, [::]:9100->80/tcp
   canvas-lms-jobs-1           canvas-lms-jobs              80/tcp
   canvas-lms-webpack-1        canvas-lms-webpack           80/tcp
   canvas-lms-canvasrceapi-1   instructure/canvas-rce-api   0.0.0.0:3100->80/tcp, [::]:3100->80/tcp
   canvas-lms-redis-1          redis:alpine                 6379/tcp
   canvas-lms-postgres-1       canvas-lms-postgres          5432/tcp
   canvas-lms-mailcatcher-1    instructure/mailcatcher      1025/tcp, 8080/tcp
   ```
#### c. In your `/etc/apache2/sites-available/` directory add a `canvas.conf` file:
```
<VirtualHost *:80>
    ServerName canvas.docker

    ProxyPreserveHost On
    ProxyRequests Off

    ProxyTimeout 300
    Timeout 300
    ProxyIOBufferSize 1048576

    # RCE API service
    ProxyPass        /rce/   http://127.0.0.1:3100/
    ProxyPassReverse /rce/   http://127.0.0.1:3100/

    # Main Canvas app
    ProxyPass        /       http://127.0.0.1:9100/
    ProxyPassReverse /       http://127.0.0.1:9100/

    ErrorLog ${APACHE_LOG_DIR}/canvas_error.log
    CustomLog ${APACHE_LOG_DIR}/canvas_access.log common
</VirtualHost>
```
#### d. Enable the site and restart Apache
```
sudo a2enmod proxy proxy_http
sudo a2ensite canvas.conf
sudo apachectl configtest # Syntax OK expected
sudo systemctl restart apache2
```
#### e. Add entry to `etc/hosts` file
```
127.0.0.1 canvas.docker
```

At this stage your Canvas environment should be accessible via http://canvas.docker and visiting http://canvas.docker/rce/ should display a blank page with the text: `Hello, from RCE Service`.

**Note:** RCE is not fully configured unless you can successfully use its editing features and upload media. Further configuration such as cloning and installing RCE standalone might be needed if the rich content editor is not fully functional in Canvas after following the stated steps. See the [official docs](https://github.com/instructure/canvas-rce-api/blob/master/README.md) for guidance.


### 10. Tunneling your local Canvas
`canvas.docker` only exists on your machine and isn’t resolvable from the internet meaning a LTI launch cannot be completed as the first step is for Canvas to initiate a login request as part of the OAuth flow.

One solution to this is connecting localhost to the internet via tunneling. There are a bunch of options like ngrok, cloudfared, localtunnel, playit(.)gg, zrok(.)io and so on. The main requirement is a service that grants **a static public url that will not change with every run of the service**. 

Note that this differs from services offering custom subdomains as we do not want to create one but rather use the static public url provided to expose localhost to the internet.

#### a. Installing and setting up tunneling service: 
I settled on using Zrok as it is open-source and also available as SaaS or self hosted. To set it up, follow the steps in this [guide](https://docs.zrok.io/docs/getting-started/), taking note to create a [reserved public share](https://docs.zrok.io/docs/concepts/sharing-reserved/) specifically (to get a static url).

Whatever service you choose, take note of the provided url as it will be used in the next steps.

#### b. Add public url as a ServerAlias in the Apache virtual host file:
In your `/etc/apache2/sites-available/` directory, open the `canvas.conf` file and edit it:
```
<VirtualHost *:80>
    ServerName canvas.docker
    ServerAlias your-public-url-here
   ...
```
Save your changes and restart apache: `sudo systemctl restart apache2`

#### c. Add additional host to Canvas:
Go to `docker-compose.override.yml` and add the `ADDITIONAL_ALLOWED_HOSTS` variable and then the url:

```
 web:
    <<: *BASE
    ports:
      - "9100:80"
    environment:
      <<: *BASE-ENV
      VIRTUAL_HOST: .canvas.docker
      HTTPS_METHOD: noredirect
      ADDITIONAL_ALLOWED_HOSTS: your-public-url-here
```
Skipping this step would result in a `Blocked hosts` error from Rails/the canvas app.

Save your changes and restart the docker containers: `docker compose down` and `docker compose up -d`

At this stage, you should be able to access the canvas environment via the public url. 

## Integrate the Dashboard into Canvas

### Install the Dashboard's LTIAAS tool in your canvas environment
The first step is installing the Dashboard's LTIAAS tool into the canvas environment / instance and then registering your canvas instance in LTIAAS.

Detailed instructions can be found here: [Canvas manual registration](https://docs.ltiaas.com/guides/lms/canvas#manual-registration).


### Test launch
If installation was successful, depending on the placement chosen (See [Canvas Placements](https://docs.ltiaas.com/guides/lms/canvas#canvas-placements)), the tool should now appear within Canvas.

Without further configuration, if you click the tool, you would either get errors like:
```
{
  "status": 400,
  "error": "Bad Request",
  "details": {
    "message": "UNREGISTERED_OR_INACTIVE_PLATFORM",
    "bodyReceived": {
      "iss": "https://canvas.instructure.com/",
```
or `This site can't be reached, canvas.docker refused to connect.`

These errors can be solved by:

#### 1. Changing the `iss` value in `config/security.yml` to your public url
```
production: &default
  encryption_key: <%= ENV["ENCRYPTION_KEY"] %>
  jwt_encryption_keys:
    - 68ddd5576efad4bc90eed3ab0543a1112b0f51ec9425573a80a96cbc4a9e12b6
  lti_iss: 'your-public-url'
```
Note: Make sure the `iss` value here matches exactly with what is registered in LTIAAS, down to the prescence of a closing `/`.

#### 2. Changing the domain in `config/domain.yml` to your public url
```
development:
  domain: "your-public-url"
```
This is needed because the domain set here is what Canvas claims its identity is and uses for OAuth, the LTI flow, JWKS endpoints and absolute URL generation. `canvas.docker` fails here because it is http only and OAuth and LTI 1.3 require https.


## Beyond a basic launch: NRPS roster + AGS grade passback

Once a basic launch works, the integration adds three flows on top of the launch handshake:

1. **Course binding** (`LtiCourseBinding`) — first instructor launch lands on a setup view at `/lti?ltik=...` where the instructor links the Canvas course to an existing Wiki Education dashboard course (or creates a new one in a separate tab and comes back). The setup view also presents the Canvas gradebook layout choice (`standard`: trainings roll-up + auto-created per-exercise columns; `per_block`: a column per graded block; `lumped`: roll-up only, exercise columns added manually via deep linking) which is stored on the binding.
2. **NRPS roster sync** — the Canvas course roster is pulled via LTIAAS Names and Roles Provisioning. New students appear as `LtiContext` rows; those whose Canvas email matches an existing dashboard `User.email` are auto-linked and enrolled in the bound course. Unmatched students get linked when they personally launch from Canvas and complete Wikipedia OAuth.
3. **AGS grade passback** — training and exercise completion is pushed back to the Canvas gradebook every 30 minutes via LTIAAS Assignment and Grade Services. Sandbox URLs for completed exercises (bibliography, outline, etc.) are included as score comments.

### Required LTIAAS scopes

The LTIAAS tool registration must include:

- **NRPS read** — to pull rosters
- **AGS line items** — to create/update/list gradebook columns
- **AGS scores** — to post per-student scores

If any of these are missing, the relevant Sidekiq jobs will surface 4xx errors from LTIAAS into Sentry.

### Placements

The integration registers three Canvas placements, each with its own
`target_link_uri`:

| Placement | `target_link_uri` | Purpose |
|---|---|---|
| Course Navigation | `https://<domain>/lti` | The "Wiki Education Dashboard" tab in the course sidebar — the instructor's and student's entry point. |
| Assignment / Link Selection | `https://<domain>/lti/deep_link` | The deep-link picker (reached from a Canvas assignment's "External Tool → Find") that creates a Wikipedia gradebook column for a training/exercise. |
| Assignment View | `https://<domain>/lti/assignment_view` | The per-milestone drill-down opened from a Wikipedia column's assignment: the instructor roster with inline sandbox previews, or the launching student's own panel. |

Course Navigation config (`text: Wiki Education Dashboard`, `enabled: true`):

- **`default: enabled`** — the tab appears in every course automatically.
- **`default: disabled`** — the tool is installed but off; each instructor opts
  in per course via **Settings → Navigation**. Switching between these is a
  developer-key placement setting in Canvas; nothing in the codebase changes.

`visibility` controls who sees the tab (`admins` / `members` / `public`).

### Service authentication (background workers)

LTIAAS issues a long-lived `serviceKey` per launch context, surfaced in `idtoken.services.serviceKey`. The dashboard captures this key on every launch and persists it on `LtiCourseBinding.ltiaas_service_credentials`. Background workers (NRPS roster sync, AGS line-item sync, AGS grade sync) authenticate with the `SERVICE-AUTH-V1 <api_key>:<service_key>` header — the `<api_key>` is the same `LTIAAS_API_KEY` used for launch-time LTIK auth.

The serviceKey is refreshed on every launch in case the underlying NRPS/AGS endpoint URLs change (per LTIAAS docs).

### Feature flag

All Canvas-integration entry points (the `/lti` routes, the periodic workers, the Block / Wizard hooks that enqueue them) are gated behind:

```
canvas_integration_enabled: 'true'
```

in `config/application.yml`. Default is `'false'` so production stays inert until LTIAAS is registered against a live Canvas instance and the flag is flipped explicitly.

## Installing at a partner university (Canvas admin walkthrough)

The real-world install path, from the perspective of a **Canvas admin at a
partner university**. On Instructure-hosted Canvas they have **root-account**
admin access but **not Site Admin** (that belongs to Instructure).
`canvas.wikiedu.org` is self-hosted, so Site Admin exists there — but we install
at the root account precisely so this walkthrough matches what a partner does.

### 1. The request

A course instructor — already using the Wiki Education Dashboard for their
Wikipedia assignment — asks their Canvas admin to add the integration, so that
training and exercise progress shows up in the Canvas gradebook and students can
launch the Dashboard from the course.

### 2. Evaluate the integration

Before installing anything account-wide, the admin does the usual vendor due
diligence:

- **Canvas integration guide** — what the tool is (an LTI 1.3 tool fronted by
  LTIAAS), what it does (course-navigation launch, NRPS roster sync, AGS grade
  passback), and what it needs (a root-account install with specific scopes and
  placements). [PLACEHOLDER - link to Wiki Education's Canvas integration guide]
- **VPAT** (Voluntary Product Accessibility Template) — the Dashboard's
  accessibility conformance report, which the university's accessibility office
  will ask for: [VPAT 2.5, WCAG edition](https://dashboard.wikiedu.org/accessibility)
  (evaluates against WCAG 2.1 A/AA).
- **HECVAT** (Higher Education Community Vendor Assessment Toolkit) — the
  security/privacy self-assessment for the university's vendor-risk review.
  [PLACEHOLDER - link to the Dashboard's HECVAT, or note its status]
- **Data flow** (for the security review): the tool is fronted by **LTIAAS**, a
  third-party LTI service. Roster data (NRPS) and grade data (AGS) flow
  Canvas ↔ LTIAAS ↔ Dashboard; the Dashboard stores the linked Canvas identities
  and pushes fractional scores plus sandbox-link comments back. See
  [Beyond a basic launch](#beyond-a-basic-launch-nrps-roster--ags-grade-passback).

### 3. Register the university's Canvas with LTIAAS

The Dashboard is fronted by a shared LTIAAS tenant, so each university's Canvas
is registered with LTIAAS once.

> [CONFIRM: who performs this hand-off — does the university admin self-register
> in the LTIAAS portal, or does Wiki Education register the platform given the
> university's Canvas issuer + client_id? Document the actual process here.]

Either way, the registration needs the university's Canvas **issuer** and the
**Client ID** from the developer key in the next step, so create the key first
and hand those two values to whoever completes the LTIAAS registration.

### 4. Create the LTI 1.3 developer key (root account)

**Admin → Developer Keys → + Developer Key → + LTI Key.** Paste Wiki Education's
LTIAAS tool configuration (JSON URL or paste JSON), set the redirect URIs,
**Save**, then set **State → ON**. Note the generated **Client ID**. See
[Placements](#placements) and [Required LTIAAS scopes](#required-ltiaas-scopes)
for what the configuration contains.

### 5. Install the app (root account)

**Admin → Apps → + App → By Client ID** → paste the Client ID → **Install**. The
tool now lives on the root account, available to every course and sub-account.
Confirm the scopes (NRPS, AGS line items, AGS scores) and the placements are
present — this is the read-only state the admin screenshot capture documents.

### 6. Choose how it appears (course-navigation default)

- **`default: disabled`** (recommended for a first rollout) — installed but off;
  the requesting instructor turns it on for just their course via
  **Settings → Navigation**, and no other course changes.
- **`default: enabled`** — the tab appears in every course automatically.

### 7. Hand back to the instructor, and verify

Tell the instructor the tool is available. They enable it in their course (if
it's default-disabled) and complete the Dashboard-side setup — linking the
Canvas course to their Wiki Education course. Confirm a test launch reaches the
Dashboard and, once the instructor binds the course, that the roster and
gradebook columns sync. The full check is in
[End-to-end manual test](#end-to-end-manual-test-live-ltiaas--canvas).

## End-to-end manual test (live LTIAAS + Canvas)

A full walkthrough of the four roles, in the order they happen. Staging pair:
`canvas.wikiedu.org` ↔ `dashboard-testing.wikiedu.org`. You need an instructor
and a student Canvas account enrolled in a test course, each able to connect a
Wikipedia account.

### 0. Admin — confirm install & configuration

The tool is installed once per Canvas instance (see
[Integrate the Dashboard into Canvas](#integrate-the-dashboard-into-canvas));
on staging it already is. Confirm:

- **Admin → Developer Keys**: the Dashboard LTI key is **ON**.
- **Admin → Apps → Manage**: the tool shows **On / Up to date**.
- The [placements](#placements) and [required LTIAAS scopes](#required-ltiaas-scopes)
  are registered, and the Course Navigation `default` is set how you want it
  (`enabled` = tab in every course; `disabled` = instructors opt in per course).
- Dashboard side: `canvas_integration_enabled: 'true'` plus `LTIAAS_DOMAIN` /
  `LTIAAS_API_KEY` in `config/application.yml`.

### 1. Instructor — prepare the course

Prereq: a Wiki Education dashboard course that is **created and approved** (in a
campaign) to link. If you don't have one, create it on the dashboard first
(instructor orientation → Create Course) and get it approved.

1. **Enable the tab** (only if Course Navigation is `default: disabled`):
   **Course → Settings → Navigation → enable "Wiki Education Dashboard" → Save.**
2. Click the **Wiki Education Dashboard** tab. Inside the Canvas iframe is a
   minimal landing (Wiki Ed wordmark + "Open the Wiki Education Dashboard").
   The button opens `/lti/connect_course?ltik=...` in a new tab
   (`target=_blank`), leaving Canvas in place. If you're not signed in you're
   bounced through Wikipedia OAuth at top level and returned to the setup view
   at `/lti?ltik=...`.
3. **Bind the course**: in the setup view, pick your approved course from the
   dropdown (or use the create-a-course link if you have none), pick a gradebook
   layout (standard is the default), and **Link this course**. Expect a redirect
   to `/courses/<slug>`; the course home's "Canvas link" panel shows the linked
   course, last sync, and synced-students count.
4. **Create the exercise columns** (lumped mode only): for each exercise you
   want graded, **Assignments → + Assignment → Submission Type: External Tool →
   Find → Wiki Education Dashboard → pick the task → Save & Publish.** (Standard
   mode auto-creates a column per exercise, and per-block mode a column per
   block; no deep-linking needed in either.)
5. Open the Canvas **Gradebook** — expect **Wikipedia account**, **Wikipedia
   trainings**, and a `Wk# <exercise>` column per deep-linked exercise (short
   labels, e.g. `Wk3 Bibliography`).

Verify (Rails console): `LtiContext.where(lti_course_binding_id: <id>)` shows a
row per Canvas member within seconds of the bind; members whose email matches a
dashboard `User.email` also appear as `CoursesUsers` enrolments.

### 2. Student — do the assignments

1. As a student, click the tab (or a deep-linked assignment). Same iframe
   landing → top-level handoff → **Wikipedia OAuth on first launch** → redirect
   to `/courses/<slug>`, enrolled. Later launches skip the OAuth step. (Before
   the instructor links/approves, students see "…is being set up" or
   "…awaiting Wiki Education approval".)
2. On the course home, complete the **Wikipedia trainings** and the timeline
   **exercises** (evaluate an article, create/edit the sandbox, bibliography,
   …). Connecting marks "Wikipedia account"; each completed item marks its
   column.

### 3. Instructor — grade & review

1. Progress syncs back automatically: roster within seconds of a launch;
   **grades every 30 minutes** via AGS.
2. Gradebook: **Wikipedia account** = 1 for connected students; **Wikipedia
   trainings** pushes `completed_count / total_count` with a
   `<count> of <total> trainings completed` score comment; each exercise column
   = `1.0` with the **sandbox URL** in the score comment. Per-(student, line
   item) dedup avoids redundant pushes when nothing changed.
3. **Drill-down**: open a Wikipedia column's **assignment → Open the Wiki
   Education Dashboard** → the per-milestone roster (each student's status +
   sandbox; **Show** previews the sandbox inline, **Open on Wikipedia** opens
   the page). A student opening the same assignment sees only their own panel.

## Production rollout checklist

Before flipping `canvas_integration_enabled` to `'true'` in production:

1. **LTIAAS prod tenant registered against the production Canvas (canvas.wikiedu.org)** with NRPS, AGS line items, and AGS scores scopes enabled. LTIAAS handles `iss` verification on every launch; the dashboard trusts the LTIAAS-issued idtoken JWT, so there is no `iss` value to configure on the dashboard side.
2. **`config/application.yml`** on the prod box — `LTIAAS_DOMAIN`, `LTIAAS_API_KEY`, and `canvas_integration_enabled: 'true'` set.
3. **Migrations applied** — three migrations from PR 1 (`create_lti_course_bindings`, `create_lti_line_items`, `add_binding_fields_to_lti_contexts`) plus `create_lti_score_signatures` from the dedup pass.
4. **Sidekiq cron loaded** — confirm `LtiDailyRosterSyncWorker` and `LtiPeriodicGradeSyncWorker` appear in the cron list (check the sidekiq-cron dashboard at `/sidekiq/cron`).
5. **Sentry monitoring** — confirm Sentry's `extra` filter doesn't drop fields named `binding_id`, `user_lti_id`, or `lineitem_id` (used by per-record error capture in the sync services).
6. **Smoke test** against `dashboard-testing.wikiedu.org` ↔ `canvas.wikiedu.org` first; only flip prod after the staging end-to-end checklist passes.

## Other Guides, References and Sources
- [Troubleshooting error messages by LTIAAS](https://docs.ltiaas.com/guides/troubleshooting/troubleshooting_error_messages)
- [Collection of LTI Related Links by LTI Bootcamp](https://github.com/1EdTech/ltibootcamp)
- [LTIAAS authentication guide](https://docs.ltiaas.com/guides/api/authentication) (covers SERVICE-AUTH-V1 vs. LTIK-AUTH-V2)
- [LTIAAS async API guide](https://docs.ltiaas.com/guides/api/async) (background-job patterns)
- [LTIAAS NRPS / Names and Roles](https://docs.ltiaas.com/api/get-memberships/)
- [LTIAAS AGS / Manipulating grade lines](https://docs.ltiaas.com/guides/api/manipulating-grade-lines/)
- [LTIAAS AGS / Manipulating grades](https://docs.ltiaas.com/guides/api/manipulating-grades/)
