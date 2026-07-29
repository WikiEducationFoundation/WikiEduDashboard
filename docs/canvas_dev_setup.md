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
- [Upgrading the test Canvas](#upgrading-the-test-canvas)
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



## Upgrading the test Canvas

`canvas.wikiedu.org` is our own Docker-Compose Canvas at `/opt/canvas-lms`
(bind-mounted into the `web` container, `RAILS_ENV: development`, started by
`docker-compose-app.service` as the `emptycodes` user). Canvas ships fixes we
need — the LTI deep-linking `module_name` claim, for instance, only started
working in `8565b537` (2026-04-09) — so it needs bumping now and then.

Done once, 2026-02-11 → 2026-05-20, in about 35 minutes of downtime. The
sequence, and the traps:

1. **Back up first.** Migrations are effectively one-way, so the dump *is* the
   rollback: `docker exec canvas-lms-postgres-1 pg_dump -U postgres
   canvas_development | gzip > …`. Note the live DB is `canvas_development`
   (dev mode), not `canvas_production`. Also save `git rev-parse HEAD`, the
   `docker images` IDs (old images aren't pruned, so they can be retagged to
   roll back), and `git diff` — see the next point.
2. **Preserve the local modifications.** The checkout carries two:
   `config/environments/development.rb` forces `https` in generated URLs
   (without it LTI launches break behind the TLS terminator) and
   `docker-compose/rce-api.override.yml` sets the RCE `VIRTUAL_HOST`. Save
   them as a patch, `git stash`, switch branch, then re-apply.
3. **Work as `emptycodes`, not root**, or you leave root-owned files in the
   tree. (Root also needs `git -c safe.directory=/opt/canvas-lms` to read the
   repo at all.)
4. `systemctl stop docker-compose-app`, fetch, `git checkout -B stable/<date>
   origin/stable/<date>`, re-apply the patch, `docker compose build`.
5. **Don't bother with `script/docker_dev_update.sh`** — it can't run
   unattended. It dies on `tput` unless `TERM` is set, then blocks on a
   `/dev/tty` prompt asking whether to rebuild images. Run its steps directly
   instead (they're in `script/common/canvas/build_helpers.sh`):

   ```bash
   docker compose up -d
   docker compose run --rm -T web bundle install
   docker compose run --rm -T web bundle exec rake js:yarn_install
   docker compose run --rm -T web bundle exec rake canvas:compile_assets_dev
   docker compose run --rm -T web bundle exec rake db:migrate RAILS_ENV=development
   docker compose run --rm -T web bundle exec rake db:migrate RAILS_ENV=test
   ```

   `db:migrate:status` will still show one `down` afterwards — the
   `99999999999999999999 Ensure test db empty` sentinel never runs in
   development. That's expected, not a failed migration.
6. **Verify the LTI registration survived**: tool privacy still `anonymous`,
   `course_navigation` still `default: disabled`, all placements present (see
   the admin checks in the [end-to-end manual test](#0-admin--confirm-install--configuration)),
   then run the staging screenshot harness.
7. **Expect UI drift to break the harness.** The 2026-05 upgrade moved the
   per-module kebabs ahead of the Modules-page settings kebab in the DOM, so
   an unscoped `first('a.al-trigger')` opened the wrong menu, and Canvas's
   new-user tutorial tray began floating over the header and intercepting
   clicks. Fixes: scope to `.module_index_tools a.al-trigger`, and turn the
   tray off for the harness user —
   `PUT /api/v1/users/<id>/features/flags/new_user_tutorial_on_off?state=off`.

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

1. **Course binding** (`LtiCourseBinding`) — first instructor launch lands on a setup view at `/lti?ltik=...` where the instructor links the Canvas course to an existing Wiki Education dashboard course (or creates a new one in a separate tab and comes back). The integration is deep-link-first and has one gradebook layout: the instructor imports the columns they want via the Modules deep-link flow, and the Dashboard auto-creates nothing. (Two auto-creating layouts, selected by a `gradebook_granularity` column, existed during development and were removed before release along with the column.)
2. **NRPS roster sync** — the Canvas course roster is pulled via LTIAAS Names and Roles Provisioning. New members appear as `LtiContext` rows, unlinked (`user_id` nil) — the anonymized roster carries only an opaque LMS id and role, no email to match on. Each links and enrolls when they personally launch from Canvas and complete Wikipedia OAuth — from the course-navigation tab or from any Wikipedia assignment, since a course may not have the tab enabled at all.
3. **AGS grade passback** — training and exercise completion is pushed back to the Canvas gradebook every 30 minutes via LTIAAS Assignment and Grade Services. Score comments carry only a lateness marker and the Dashboard's origin; sandbox URLs are deliberately kept out of them, because they embed the student's Wikipedia username and gradebook comments are visible to everyone with gradebook access (see `LtiBlockProgress`). Instructors reach a student's sandbox through the role-gated in-Canvas drill-down instead.

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
| Course Navigation | `https://<domain>/lti` | The "Wiki Education Dashboard" tab in the course sidebar — a convenient entry point, and the home of the instructor's sync-status view. Optional: linking and student enrollment also happen from the deep-link and assignment launches, so a course with the tab off still works end to end. |
| Assignment / Link Selection | `https://<domain>/lti/deep_link` | The deep-link picker, reached from the Modules page's ⋮ menu ("Import Wikipedia assignments"), that bulk-creates the Wikipedia gradebook columns (the account indicator, the trainings roll-up, and one per exercise). |
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

## Installing on a dev / self-hosted Canvas (manual walkthrough)

How to install the tool **by hand** on a Canvas you control. This is the dev
path: a development or self-hosted Canvas (like `canvas.wikiedu.org`) typically
lacks the paid **Dynamic Registration** add-on, so you create the LTI key
yourself. Real partner institutions install via self-service Dynamic
Registration instead — paste one URL, no manual key — see the
[Canvas integration guide](./canvas_integration_guide.md) for that flow. Either
way you install at the **root account** (not Site Admin, which on
Instructure-hosted Canvas belongs to Instructure).

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
  placements). See [the Canvas integration guide](./canvas_integration_guide.md).
- **VPAT** (Voluntary Product Accessibility Template) — the Dashboard's
  accessibility conformance report, which the university's accessibility office
  will ask for: [VPAT 2.5, WCAG edition](https://dashboard.wikiedu.org/accessibility)
  (evaluates against WCAG 2.1 A/AA).
- **HECVAT** (Higher Education Community Vendor Assessment Toolkit) — the
  security/privacy self-assessment for the university's vendor-risk review. See
  the [HECVAT draft](./hecvat.md) in this repo (to be published at
  dashboard.wikiedu.org/hecvat).
- **Data flow** (for the security review): the tool is fronted by **LTIAAS**, a
  third-party LTI service. Roster data (NRPS) and grade data (AGS) flow
  Canvas ↔ LTIAAS ↔ Dashboard. The Dashboard requires and saves only an opaque
  LMS user id and role per member, so it stores just the link between that id
  and the Dashboard account, and pushes fractional scores back with comments
  that carry only a lateness marker and the Dashboard's origin — no sandbox
  links, no usernames. What Canvas actually *transmits* depends on the installed
  tool's privacy level: under Anonymous it is only the id and role, and under a
  more permissive setting Canvas also sends names and emails, which
  `LtiServiceSession#normalize_member` and `LtiSession` discard on receipt.
  Worth knowing that the admin's Anonymized choice does not currently reach the
  installed tool — see
  `.claude/canvas_integration/canvas_overlay_privacy_bug_brief-2026-07-27.md`.
  See
  [Beyond a basic launch](#beyond-a-basic-launch-nrps-roster--ags-grade-passback).

### 3. Register the university's Canvas with LTIAAS

The Dashboard is fronted by a shared LTIAAS tenant, so each university's Canvas
is registered with LTIAAS once.

> [PLACEHOLDER - who performs this hand-off: does the university admin
> self-register in the LTIAAS portal, or does Wiki Education register the platform
> given the university's Canvas issuer + client_id? Needs the actual operational
> process from the operator. Was written as a `[CONFIRM: ...]` note, which the
> `grep '[PLACEHOLDER'` sweep for unresolved copy doesn't catch.]

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
- **Privacy level is `anonymous` on the _installed_ tool.** What Canvas shares
  (launch claims *and* the NRPS roster) is governed by the installed tool, which
  can drift from the developer key's `tool_configuration` — on staging the key's
  config said `anonymous` while the installed tool was still `public`, so NRPS
  was returning names and emails (the Dashboard discards them, but they were
  being sent). Check and fix over the API:

  ```bash
  # what the installed tool actually uses
  curl -H "Authorization: Bearer $TOKEN" \
    "$CANVAS/api/v1/accounts/1/external_tools/<tool_id>" | jq .privacy_level
  # what the developer key's config asks for
  curl -H "Authorization: Bearer $TOKEN" \
    "$CANVAS/api/lti/accounts/1/developer_keys/<key_id>/tool_configuration" \
    | jq '.tool_configuration.settings.extensions[0].privacy_level'
  # correct the installed tool
  curl -X PUT -H "Authorization: Bearer $TOKEN" \
    "$CANVAS/api/v1/accounts/1/external_tools/<tool_id>" -d privacy_level=anonymous
  ```
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
   dropdown (or use the create-a-course link if you have none) and **Link this
   course** — there's no gradebook-layout choice; the integration is
   deep-link-first. Expect a redirect to `/courses/<slug>`; the course home's
   "Canvas link" panel shows the linked course, last sync, and synced-students
   count.
4. **Import the assignments**: on the **Modules** page, open the **⋮ (options)**
   menu at the top and choose **Wiki Education Dashboard** ("Import Wikipedia
   assignments"). This deep-links every column at once — the "Wikipedia account"
   indicator, the "Wikipedia trainings" roll-up, and one per exercise — and
   Canvas creates a module with an assignment per column. They arrive
   unpublished; publish them so students can open them.
5. Open the Canvas **Gradebook** — expect **Wikipedia account**, **Wikipedia
   trainings**, and a `Wk# <exercise>` column per imported exercise (short
   labels, e.g. `Wk3 Bibliography`).

Verify (Rails console): `LtiContext.where(lti_course_binding_id: <id>)` shows a
row per Canvas member within seconds of the bind — unlinked (`user_id` nil)
until each student connects a Wikipedia account by launching, since the
anonymized roster carries no email to auto-enroll against.

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
   = `1.0`, with a `[Late]` marker in the comment when it was completed after the
   block's due date. Sandbox URLs never appear in a comment. Per-(student, line
   item) dedup avoids redundant pushes when nothing changed.
3. **Drill-down**: open a Wikipedia column's **assignment → Open the Wiki
   Education Dashboard** → the per-milestone roster (each student's status +
   sandbox; **Show** previews the sandbox inline, **Open on Wikipedia** opens
   the page). A student opening the same assignment sees only their own panel.

### "Refused to connect" in the Canvas frame — what it means

Worth recognizing when supporting a launch, because the message is usually a
symptom rather than the problem. The Dashboard sends Rails' default
`X-Frame-Options: SAMEORIGIN` on everything, and `allow_iframe` strips it on
exactly the launch endpoints (`launch`, `assignment_view`, `complete_setup`,
`deep_link`, `deep_link_select`, `sync_grades`). Anything else the iframe lands
on refuses to render. So the message means the frame is showing a Dashboard URL
that isn't one of those — in practice:

- **A launch that errored.** `config.exceptions_app = self.routes`, so error
  pages render through `ErrorsController` and carry `SAMEORIGIN` — Canvas shows
  "Refused to connect" *instead of* the error. A blank/missing `ltik` does the
  same via `/errors/login_error`. Check the app logs (on staging, Apache's
  `error.log`), not the browser.
- **`canvas_integration_enabled` is not `'true'`.** The gate returns
  `head :not_found`, and a halted `before_action` skips `after_action`, so the
  404 keeps the header.
- **The frame navigated to a normal Dashboard page** — course pages, sign-in,
  training modules all refuse. In-iframe views link out with `target="_blank"`
  precisely to avoid this; a link that loses it reintroduces the bug.
- **Wikipedia OAuth in the frame.** Wikimedia refuses framing outright, which
  is why account linking breaks out to a new tab via `connect_course` (itself
  `SAMEORIGIN`, so loading it framed shows the message).

Not to be confused with blocked third-party cookies, which never produce this
message — a partitioned cookie jar makes the iframe read as logged-out, which
`LtiAnonymousLaunch` handles by rendering read-only views from the `ltik`.

## Production rollout checklist

Before flipping `canvas_integration_enabled` to `'true'` in production:

1. **LTIAAS prod tenant configured** with NRPS, AGS line items, and AGS scores scopes enabled. LTIAAS handles `iss` verification on every launch; the dashboard trusts the LTIAAS-issued idtoken JWT, so there is no `iss` value to configure on the dashboard side. Note there is no "Wiki Education production Canvas" to register against: each institution registers the tool into **their own** Canvas (dynamic registration), and `canvas.wikiedu.org` exists only to develop and test the integration.
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
