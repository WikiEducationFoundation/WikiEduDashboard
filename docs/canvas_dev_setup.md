[Back to README](../README.md)

There is ongoing work to integrate the Dashboard with the widely-used **[Canvas LMS](https://community.instructure.com/en/kb/articles/662716-what-is-canvas)**. This integration is made possible using the **[IMS LTI Standard](https://www.1edtech.org/standards/lti)**.

The dashboard has integrated the third-party **[LTIAAS API](https://docs.ltiaas.com/guides/introduction)** (see [LTIAAS Integration PR](https://github.com/WikiEducationFoundation/WikiEduDashboard/pull/6201)) and is configured on the LTIAAS portal allowing the codebase act as a LTI 1.3 compliant learning tool.

To use the tool, a Canvas admin installs the Dashboard's LTIAAS tool into their canvas environment / instance by [manual registration](https://docs.ltiaas.com/guides/lms/canvas#manual-registration).

## Basic LTI Launch
Once a canvas dev environment is running locally and the LTIAAS tool is installed in it, the integration is successful if a basic LTI launch can be completed:

1. User (student/admin/other role) logs into Canvas LMS
2. User clicks on the tool link (displayed as a course assignment or as configured in Canvas)
3. Canvas initiates login with LTIAAS using an OIDC flow; uses LTI protocol to confirm user identity (see: [LTI Launch Overview](https://developerdocs.instructure.com/services/canvas/external-tools/lti/file.lti_launch_overview))
4. If successful, LTIAAS redirects user to Dashboard's lti route; currently just the home page


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

1. **Course binding** (`LtiCourseBinding`) — first instructor launch lands on a setup view at `/lti?ltik=...` where the instructor links the Canvas course to an existing Wiki Education dashboard course (or creates a new one in a separate tab and comes back). The setup view also presents the Canvas gradebook layout choice (lumped trainings vs. per-block columns) which is stored on the binding.
2. **NRPS roster sync** — the Canvas course roster is pulled via LTIAAS Names and Roles Provisioning. New students appear as `LtiContext` rows; those whose Canvas email matches an existing dashboard `User.email` are auto-linked and enrolled in the bound course. Unmatched students get linked when they personally launch from Canvas and complete Wikipedia OAuth.
3. **AGS grade passback** — training and exercise completion is pushed back to the Canvas gradebook every 30 minutes via LTIAAS Assignment and Grade Services. Sandbox URLs for completed exercises (bibliography, outline, etc.) are included as score comments.

### Required LTIAAS scopes

The LTIAAS tool registration must include:

- **NRPS read** — to pull rosters
- **AGS line items** — to create/update/list gradebook columns
- **AGS scores** — to post per-student scores

If any of these are missing, the relevant Sidekiq jobs will surface 4xx errors from LTIAAS into Sentry.

### Course Navigation placement

For v1 the integration is registered exclusively as a Course Navigation tool: a single "Wiki Education Dashboard" tab in the Canvas course sidebar. Deep linking (per-module-item content selection) is deferred. In LTIAAS' Canvas registration:

- `text`: `Wiki Education Dashboard`
- `target_link_uri`: `https://<your-public-domain>/lti`
- `default`: `enabled`
- `enabled`: `true`

### Service authentication (background workers)

LTIAAS issues a long-lived `serviceKey` per launch context, surfaced in `idtoken.services.serviceKey`. The dashboard captures this key on every launch and persists it on `LtiCourseBinding.ltiaas_service_credentials`. Background workers (NRPS roster sync, AGS line-item sync, AGS grade sync) authenticate with the `SERVICE-AUTH-V1 <api_key>:<service_key>` header — the `<api_key>` is the same `LTIAAS_API_KEY` used for launch-time LTIK auth.

The serviceKey is refreshed on every launch in case the underlying NRPS/AGS endpoint URLs change (per LTIAAS docs).

### Feature flag

All Canvas-integration entry points (the `/lti` routes, the periodic workers, the Block / Wizard hooks that enqueue them) are gated behind:

```
canvas_integration_enabled: 'true'
```

in `config/application.yml`. Default is `'false'` so production stays inert until LTIAAS is registered against a live Canvas instance and the flag is flipped explicitly.

## Manual smoke test (against a live LTIAAS + Canvas pair)

Once the LTIAAS tool is installed, `canvas_integration_enabled` is `true`, and the dashboard is reachable from your test Canvas:

1. **Instructor first launch**. As an instructor, click the "Wiki Education Dashboard" tab in a Canvas test course. Expect to land on `/lti?ltik=...` and see the setup view. If you're not signed in to the dashboard, you should be bounced to Wikipedia OAuth and returned to the setup view after sign-in.
2. **Bind to a dashboard course**. In the setup view, enter the slug of a dashboard course you're already an instructor on, pick a gradebook granularity (lumped is the default), and submit. Expect a redirect to `/courses/<slug>`.
3. **Roster sync**. Within a few seconds of the bind, every Canvas course member should appear as an `LtiContext` row (`LtiContext.where(lti_course_binding_id: <id>)` in a Rails console). Members whose email matches a dashboard `User.email` should also appear as `CoursesUsers` enrolments.
4. **Line-item sync**. Within ~2 minutes of any timeline change (or immediately after the bind), the Canvas gradebook should show columns matching the binding's granularity:
   - **Lumped**: one "Wikipedia trainings" column + one column per exercise block.
   - **Per-block**: one column per training-bearing or exercise-bearing block (`Wk1 Get started`, `Wk3 Bibliography`, etc.).
5. **Student first launch**. As a student in the Canvas course, click the tab. Expect the OAuth bounce on first launch, then a redirect to `/courses/<slug>`. Subsequent launches go straight to the course.
6. **Grade passback**. Complete a training module on the dashboard. Within 30 minutes, expect a `1.0` in the Canvas gradebook (with a `<count> of <total> trainings completed` score comment in lumped mode). Mark an exercise complete and expect a `1.0` plus the sandbox URL in the score comment.
7. **Iframe escape hatch**. If your browser blocks third-party cookies (Safari, Chrome with strict 3PC), the iframe view will still render but the inline form may not submit. Click the "Open in a new tab" button on any setup view to continue in a top-level window via `/lti/escape?ltik=...`.

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
