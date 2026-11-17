# Wiki Education's Salesforce footprint

(This document was written and compiled by Claude Code.)

Wiki Education uses Salesforce as its CRM. This document tracks how Salesforce
is set up and what depends on it, so that vendor notices (API retirements,
authentication changes, certificate policy changes, and so on) can be checked
against a known inventory instead of re-investigated each time.

The Wiki Education Dashboard is the only code that talks to Salesforce from
this repository, so most of what's below is about the Dashboard. Anything else
connected to the org belongs in [Beyond the Dashboard](#beyond-the-dashboard).
Facts there should come from the Salesforce Setup UI or from the people who
run those systems.

Programs & Events Dashboard deployments never touch Salesforce. Every entry
point checks `Features.wiki_ed?`.

## The org

| | |
|---|---|
| My Domain | `wikied` — `https://wikied.my.salesforce.com/` (`SF_SERVER`), Lightning UI at `wikied.lightning.force.com` |
| Older URLs | Records were once linked as `https://cs54.salesforce.com/<id>` (see `salesforce_utils.js`); `cs54` also appears as a dummy value in `config/environments/test.rb` |
| Sandboxes | ? |
| Administrators | ? |

## How the Dashboard connects

All API traffic is **outbound from the Dashboard server to Salesforce**. No
route exists for Salesforce to call the Dashboard, and no Salesforce webhooks or
outbound messages point at it.

- **Client:** the [Restforce](https://github.com/restforce/restforce) gem
  (8.0.1 in `Gemfile.lock`), using the REST API.
- **API version:** `SALESFORCE_API_VERSION: '38.0'` in
  `config/application.production.yml`. That version is old. Check it first when
  Salesforce announces an API version retirement.
- **Authentication:** OAuth through a Connected App. `Restforce.new` is called
  with the `salesforce` row of the `settings` table (`SalesforceCredentials`).
  That row holds `password` and `security_token`. Restforce fills in everything
  else from environment variables: `SALESFORCE_USERNAME`,
  `SALESFORCE_CLIENT_ID` and `SALESFORCE_CLIENT_SECRET`. The production config
  template lists those plus `SALESFORCE_PASSWORD` and
  `SALESFORCE_SECURITY_TOKEN`, so this is the **username-password OAuth flow**.
  - Admins can replace the password and security token at `/settings`
    ("Update Salesforce credentials") without a deploy. That's needed whenever
    the integration user's password changes, because Salesforce issues a new
    security token on every password reset.
  - **Login host:** `login.salesforce.com`, Restforce's default
    (`SALESFORCE_HOST` isn't in the production config template).
  - `docs/salesforce_scripts/connect_courses_to_salesforce.rb` calls
    `Restforce.new` with no arguments, so it runs on environment variables alone.
- **Integration user:** whoever `SALESFORCE_USERNAME` names. Its profile and
  permissions: ?

### Credentials and certificates

| Item | Where it lives | Notes |
|---|---|---|
| Connected App consumer key / secret | `SALESFORCE_CLIENT_ID`, `SALESFORCE_CLIENT_SECRET` in `config/application.yml` on the server | Connected App name: ? |
| Integration user password + security token | `settings` table (`key: 'salesforce'`), env vars as fallback | Rotatable from `/settings` |
| Client certificates for mutual TLS | **None.** The Dashboard doesn't use mTLS with Salesforce | |

## What the Dashboard reads and writes

### Objects and fields

| Salesforce object | Direction | Code | What |
|---|---|---|---|
| `Course__c` | write (create/update) | `PushCourseToSalesforce` | ~30 fields: title, URLs, dates, participant/edit/word/view/upload counts, assignment-block dates, assignment-wizard tags, content expert, submitted/approved timestamps, AI-alert counts, Wikidata stats. See `base_salesforce_fields`. |
| `Course__c` | read | `UpdateCourseFromSalesforce` | `Course_Closed_Date__c`, stored as `course.flags[:closed_date]` |
| `Engagement__c` (record type "Media") | write (create) | `CreateSalesforceMediaRecord` | One record per article contribution an admin chooses to credit |
| `Account` (Institution record type) | write (create) | `docs/salesforce_scripts/add_institutions_from_csv.rb` | One-off script for importing HBCUs |
| Search (SOSL) | read | `docs/salesforce_scripts/connect_courses_to_salesforce.rb` | One-off script matching Dashboard courses to existing records |

A course is linked to its Salesforce record by `course.flags[:salesforce_id]`
(a 15- or 18-character record ID).

Org-specific IDs the code depends on:

| ID | Source |
|---|---|
| Program records for Classroom Program, Visiting Scholars and Wikipedia Fellows | `SF_CLASSROOM_PROGRAM_ID`, `SF_VISITING_SCHOLARS_PROGRAM_ID`, `SF_WIKIPEDIA_FELLOWS_PROGRAM_ID` (`SalesforceHelper#program_id`) |
| Media record type on `Engagement__c` | `SF_MEDIA_ENGAGEMENT_TYPE_ID` (not listed in `application.production.yml`) |
| Content experts' Salesforce IDs, keyed by Wikipedia username | `settings` table, `key: 'content_expert_salesforce_ids'` |
| Institution Account record type | Hard-coded in `add_institutions_from_csv.rb` |

Renaming or deleting any of these objects, fields, record types or program
records in Salesforce breaks the sync. Update failures are reported to Sentry
(`Faraday::ParsingError`, `Restforce::NotFoundError`, or any error on the
read side).

### When it happens

- **Daily:** `DailyUpdate` → `SalesforceSyncWorker`. Pushes every current,
  approved, linked course. Pulls the closed date for every ended, approved,
  not-withdrawn, not-yet-closed `ClassroomProgramCourse`.
- **Admin actions** (`SalesforceController`, admin-only):
  - Linking a course, on the approval form or with the "Link to Salesforce"
    button, triggers an immediate push.
  - "Update Salesforce record" pushes on demand.
  - The article diff viewer's "Create a new Salesforce Media record" buttons
    create an `Engagement__c` and then redirect to it.

### What leaves the Dashboard

Records are course-level only: no student names or email addresses. See the
Salesforce entry in the subprocessor list in `docs/hecvat.md`.

## Email to Salesforce (BCC)

Separately from the API, some Dashboard emails are BCC'd to a Salesforce
email-logging address so they're recorded against contacts in Salesforce. Two
environment variables are in use:

| Variable | Used by |
|---|---|
| `bcc_to_salesforce_email` | Automated alert emails (`Alert#bcc_to_salesforce_email`): first enrolled student, no enrolled students, no TA enrolled, untrained students |
| `SALESFORCE_BCC_EMAIL` | Instructor notifications (`InstructorNotificationMailer`) and ticket replies (`TicketNotificationMailer`), both optional via a checkbox |

The production config template lists only `bcc_to_salesforce_email`. If
`SALESFORCE_BCC_EMAIL` isn't set on the server, those two checkboxes do
nothing.

## Browser-side links

`SF_SERVER` is exposed to the page as `window.SalesforceServer` and is used to
build "Open in Salesforce" links for admins. These are ordinary browser links
and depend on staff being able to log into the org, not on the API connection.

## Beyond the Dashboard

Other systems connected to the org aren't visible from this repository. Fill
these in as they're confirmed:

- Other Connected Apps / integrations (Setup → App Manager, Setup → Connected
  Apps OAuth Usage), as of 2026-10-29:
  - **Cirrus Insight:** some staff use it to connect their email inboxes and
    automatically record emails to Salesforce contacts.
  - **FormAssembly:** used for applications to the Scholars & Scientists
    program.
  - Anything else: ?
- Other Salesforce products in use:
  - **Account Engagement (Pardot):** sends marketing and operational emails
    related to the programs run on the Dashboard (Student Program, Scholars &
    Scientists).
- Mutual authentication certificates (Setup → Certificate and Key Management)
  and users with "Enforce SSL/TLS Mutual Authentication": ?
- Email-to-Salesforce / Email Relay configuration: ?
- Other inbound sources:
  - **wikiedu.org website** (its WordPress theme repo is on Wiki Education's
    GitHub):
    - A pair of signup interest forms that use Salesforce forms.
    - Popup forms, via WordPress plugins, that push data to Salesforce and/or
      Account Engagement.
  - Anything else (donation or event platforms, data imports): ?
- Outbound calls from Salesforce (Named Credentials, Remote Site Settings,
  outbound messages, flows calling external services): ?

## Checking a vendor notice

1. Work out which kind of change it is: API version retirement,
   authentication / Connected App policy, TLS or certificates, email,
   field or object changes, or something in the Salesforce UI only.
2. Look up the matching part of this document. Things the Dashboard itself
   depends on are the API version, the username-password OAuth flow and
   Connected App, the objects and fields listed above, and email BCC logging.
3. For anything marked `?`, check with Wiki Education staff or the Salesforce
   Setup UI, and fill it in here.
