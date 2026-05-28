# UI Inventory

A map of every user-facing HTML page in the dashboard, the Rails route that
serves it, the ERB/HAML template, and the primary React component that mounts
on it (if any). Pages are grouped by area.

Notation:
- `GET /path` — `Controller#action` → `app/views/...` → React: `ComponentName`
- "Server-rendered" means the page is a plain HAML/ERB template; React may
  still appear as small embedded widgets, but the page is not a React app.
- Many "React: X" pages mount a single root component that then runs its own
  client-side React Router. Subroutes for those pages are listed indented.

The top-level React Router config is in
`app/assets/javascripts/components/util/routes.jsx`. Course and campaign
sub-tabs are routed inside `course.jsx` and `campaigns_handler.jsx`/`campaign.jsx`.

Screenshots are checked into `docs/screenshots/`. To regenerate them all, run:

```
SCREENSHOTS=1 bundle exec rspec spec/features/ui_inventory_screenshots_spec.rb
```

The spec pins a frozen date, a stable course passcode, and (where the Rails
app makes server-side calls) replays Wikimedia API responses from
`fixtures/vcr_cassettes/cached/ui_inventory_screenshots/`. With those in
place all screenshots are byte-stable across runs except
`article_finder_results.png` (see note below).

---

## Public / unauthenticated

- `GET /` — `HomeController#index` → `home/index.html.haml` — marketing page
  shown to logged-out users; authenticated users get redirected to the
  dashboard's root React mount, which renders `DetailedCampaignList`.
  <br><a href="screenshots/home_marketing.png"><img src="screenshots/home_marketing.png" width="320" alt="home (marketing)"></a>
- `GET /explore` — `ExploreController#index` → `explore/index.html.haml` →
  React: `Explore`
  <br><a href="screenshots/explore.png"><img src="screenshots/explore.png" width="320" alt="explore"></a>
- `GET /faq` — `FaqController#index` → `faq/index.html.haml` — server-rendered
  <br><a href="screenshots/faq_index.png"><img src="screenshots/faq_index.png" width="320" alt="faq index"></a>
- `GET /faq/:id` — `FaqController#show` — server-rendered
  <br><a href="screenshots/faq_show.png"><img src="screenshots/faq_show.png" width="320" alt="faq show"></a>
- `GET /faq/new`, `/faq/:id/edit` — `FaqController` — server-rendered forms
  <br><a href="screenshots/admin_faq_new.png"><img src="screenshots/admin_faq_new.png" width="320" alt="faq new"></a>
- `GET /faq_topics`, `/faq_topics/new`, `/faq_topics/:slug/edit` —
  `FaqTopicsController` — server-rendered
  <br><a href="screenshots/faq_topics_index.png"><img src="screenshots/faq_topics_index.png" width="320" alt="faq topics index"></a>
  <a href="screenshots/admin_faq_topic_new.png"><img src="screenshots/admin_faq_topic_new.png" width="320" alt="faq topic new"></a>
- `GET /private_information` — `AboutThisSiteController#private_information` —
  server-rendered
  <br><a href="screenshots/private_information.png"><img src="screenshots/private_information.png" width="320" alt="private information"></a>

## Authentication & onboarding

- `GET /sign_in` — `ErrorsController#login_error` → `errors/login_error.html.haml`
  (this is shown when login fails or is required; the real auth handshake is
  the OAuth flow at `/users/auth/mediawiki`)
  <br><a href="screenshots/sign_in.png"><img src="screenshots/sign_in.png" width="320" alt="sign in"></a>
- `GET /sign_out` — `UsersController#signout` — redirect
- `GET /sign_out_oauth` — `Devise::SessionsController#destroy` — redirect
- `GET /onboarding(/*any)` — `OnboardingController#index` →
  `onboarding/index.html.haml` → React: `Onboarding`. The Onboarding component
  is itself a mini React Router with these sub-routes:
  - `/` — `Intro`
    <br><a href="screenshots/onboarding_intro.png"><img src="screenshots/onboarding_intro.png" width="320" alt="onboarding intro"></a>
  - `/form` — `Form`
    <br><a href="screenshots/onboarding_form.png"><img src="screenshots/onboarding_form.png" width="320" alt="onboarding form"></a>
  - `/supplementary` — `Supplementary`
    <br><a href="screenshots/onboarding_supplementary.png"><img src="screenshots/onboarding_supplementary.png" width="320" alt="onboarding supplementary"></a>
  - `/permissions` — `Permissions`
    <br><a href="screenshots/onboarding_permissions.png"><img src="screenshots/onboarding_permissions.png" width="320" alt="onboarding permissions"></a>
  - `/finish` — `Finished`
    <br><a href="screenshots/onboarding_finish.png"><img src="screenshots/onboarding_finish.png" width="320" alt="onboarding finish"></a>

## Dashboard

- `GET /` (authenticated) and `GET /dashboard` — `DashboardController#index` →
  `dashboard/index.html.haml` → React: `DetailedCampaignList` (user's courses)
  <br><a href="screenshots/dashboard_my_courses.png"><img src="screenshots/dashboard_my_courses.png" width="320" alt="dashboard my courses"></a>
- `GET /my_account` — `DashboardController#my_account`
  <br><a href="screenshots/my_account.png"><img src="screenshots/my_account.png" width="320" alt="my account"></a>

## Course page

The course page is one root React component, `Course`, with internal tabs
routed by React Router inside `course/course.jsx`:

- `GET /courses/:school/:titleterm(/:_subpage(/:_subsubpage(/:_subsubsubpage)))` —
  `CoursesController#show` → `courses/show.html.haml` → React: `Course`
  - `/` and `/home` and `/overview` — `OverviewHandler`
    <br><a href="screenshots/course_overview.png"><img src="screenshots/course_overview.png" width="320" alt="course overview"></a>
    <br>When the course's home wiki is `www.wikidata.org`, the wiki-specific
    stats tab below the main stats strip is `WikidataOverviewStats` instead
    of `NamespaceOverviewStats`. Tab is hidden if every counter is zero
    (see `overview_stats_tabs.jsx:37`), so the sparse example below still
    has a handful of non-zero counters.
    <br><a href="screenshots/course_overview_wikidata_sparse.png"><img src="screenshots/course_overview_wikidata_sparse.png" width="320" alt="course overview, wikidata stats (sparse)"></a>
    <a href="screenshots/course_overview_wikidata_rich.png"><img src="screenshots/course_overview_wikidata_rich.png" width="320" alt="course overview, wikidata stats (rich)"></a>
  - `/activity/*` — `ActivityHandler`
    <br><a href="screenshots/course_activity.png"><img src="screenshots/course_activity.png" width="320" alt="course activity"></a>
  - `/students/*` — `StudentsTabHandler`
    <br><a href="screenshots/course_students.png"><img src="screenshots/course_students.png" width="320" alt="course students"></a>
  - `/articles/*` — `ArticlesHandler`
    <br><a href="screenshots/course_articles.png"><img src="screenshots/course_articles.png" width="320" alt="course articles"></a>
  - `/uploads` — `UploadsHandler`
    <br><a href="screenshots/course_uploads.png"><img src="screenshots/course_uploads.png" width="320" alt="course uploads"></a>
  - `/article_finder` — `ArticleFinder` (same component reused from the
    standalone `/article_finder` page below)
    <br><a href="screenshots/course_article_finder.png"><img src="screenshots/course_article_finder.png" width="320" alt="course article finder"></a>
  - `/timeline/*` — `TimelineHandler` (includes the assignment wizard at
    `/timeline/wizard`)
    <br><a href="screenshots/course_timeline.png"><img src="screenshots/course_timeline.png" width="320" alt="course timeline"></a>
    <a href="screenshots/course_timeline_wizard.png"><img src="screenshots/course_timeline_wizard.png" width="320" alt="course timeline wizard"></a>
  - `/resources` — `Resources`
    <br><a href="screenshots/course_resources.png"><img src="screenshots/course_resources.png" width="320" alt="course resources"></a>

Shared chrome rendered inside `Course` regardless of tab:
- `CourseNavbar` — the tab bar
- `CourseAlerts` — banner-style alerts
- `EnrollCard` — enrollment modal

Notable cross-tab modals/panels:
- "Edit Course Dates" panel from the timeline tab — `timeline/meetings.jsx`
- Course creation wizard (when entered via `/timeline/wizard`) — see Course
  creation section below

## Course creation

- `GET /course_creator` — `DashboardController#index` →
  `dashboard/index.html.haml` → React: `ConnectedCourseCreator`. After
  creation, the user is redirected to the new course's timeline and the
  assignment design wizard runs there.

The course creator is a two-stage modal: a metadata form, then a date picker.

  <a href="screenshots/course_creator_form.png"><img src="screenshots/course_creator_form.png" width="320" alt="course creator form (empty)"></a>
  <a href="screenshots/course_creator_form_filled.png"><img src="screenshots/course_creator_form_filled.png" width="320" alt="course creator form (filled)"></a>
  <a href="screenshots/course_creator_dates.png"><img src="screenshots/course_creator_dates.png" width="320" alt="course creator date picker"></a>

- `GET /copy_course` — `CopyCourseController#index` → `copy_course/index.html.haml`
  — server-rendered form (admin-only when `Features.wiki_ed?`)
  <br><a href="screenshots/copy_course.png"><img src="screenshots/copy_course.png" width="320" alt="copy course"></a>

### Assignment design wizard ("Research and write" path)

Wizard content is data-driven via `WizardController`'s JSON endpoints; there
is no separate HTML route for the wizard — it overlays the timeline tab at
`/courses/:slug/timeline/wizard` after the course is created. The wizard
forks at step 2 by assignment type; the screenshots below show the
**"Research and write"** path, which is the main branch and which most
instructors take.

1. **Course dates** — confirm course / assignment / blackout dates.
   <br><a href="screenshots/course_wizard_dates.png"><img src="screenshots/course_wizard_dates.png" width="320" alt="wizard course dates"></a>
2. **Assignment type** — pick "Research and write", "Translate", or "Create images and multimedia".
   <br><a href="screenshots/course_wizard_path.png"><img src="screenshots/course_wizard_path.png" width="320" alt="wizard assignment type"></a>
3. **Training** — graded or ungraded.
   <br><a href="screenshots/course_wizard_training.png"><img src="screenshots/course_wizard_training.png" width="320" alt="wizard training"></a>
4. **Generative AI** — assign the LLM-and-Wikipedia training or not.
   <br><a href="screenshots/course_wizard_ai.png"><img src="screenshots/course_wizard_ai.png" width="320" alt="wizard generative AI"></a>
5. **Getting started with editing** — pick the on-ramp activities.
   <br><a href="screenshots/course_wizard_getting_started.png"><img src="screenshots/course_wizard_getting_started.png" width="320" alt="wizard getting started"></a>
6. **Improving representation** — add the diversity / equity / inclusion guidance or not.
   <br><a href="screenshots/course_wizard_representation.png"><img src="screenshots/course_wizard_representation.png" width="320" alt="wizard representation"></a>
7. **Sandboxes vs. live editing**.
   <br><a href="screenshots/course_wizard_sandboxes.png"><img src="screenshots/course_wizard_sandboxes.png" width="320" alt="wizard sandboxes"></a>
8. **Working individually or in groups**.
   <br><a href="screenshots/course_wizard_groups.png"><img src="screenshots/course_wizard_groups.png" width="320" alt="wizard groups"></a>
9. **Choosing articles** — instructor prepares a list, or students find their own.
   <br><a href="screenshots/course_wizard_articles_source.png"><img src="screenshots/course_wizard_articles_source.png" width="320" alt="wizard articles source"></a>
10. **Medical topics** — yes/no, inserts the medical-content training if yes.
    <br><a href="screenshots/course_wizard_medical.png"><img src="screenshots/course_wizard_medical.png" width="320" alt="wizard medical"></a>
11. **Subject-specific resources / handouts**.
    <br><a href="screenshots/course_wizard_handouts.png"><img src="screenshots/course_wizard_handouts.png" width="320" alt="wizard handouts"></a>
12. **Peer feedback** — 0, 1, or 2 reviews.
    <br><a href="screenshots/course_wizard_peer_review.png"><img src="screenshots/course_wizard_peer_review.png" width="320" alt="wizard peer review"></a>
13. **Discussions** — which weekly discussions to include.
    <br><a href="screenshots/course_wizard_discussions.png"><img src="screenshots/course_wizard_discussions.png" width="320" alt="wizard discussions"></a>
14. **Supplementary assignments** — weekly journal, reflective essay, extra credit, etc.
    <br><a href="screenshots/course_wizard_supplementary.png"><img src="screenshots/course_wizard_supplementary.png" width="320" alt="wizard supplementary"></a>
15. **Assignment expectations** — how much each student is expected to contribute.
    <br><a href="screenshots/course_wizard_expectations.png"><img src="screenshots/course_wizard_expectations.png" width="320" alt="wizard expectations"></a>
16. **Course weight** — share of the syllabus the Wikipedia assignment occupies.
    <br><a href="screenshots/course_wizard_weight.png"><img src="screenshots/course_wizard_weight.png" width="320" alt="wizard course weight"></a>
17. **Summary** — review every selection; clicking *Generate Timeline* writes the resulting weeks/blocks to the course.
    <br><a href="screenshots/course_wizard_summary.png"><img src="screenshots/course_wizard_summary.png" width="320" alt="wizard summary"></a>

## Campaigns

Campaign URLs are handled by **`CampaignsHandler`** at the top-level React
Router (`/campaigns/*`), which then renders **`Campaign`** for any specific
campaign. The tabs are partly React-routed and partly server-rendered:

- `GET /campaigns` — `CampaignsController#index` → `campaigns/index.html.haml`
  → React: `CampaignsHandler` (list of campaigns)
  <br><a href="screenshots/campaigns_index.png"><img src="screenshots/campaigns_index.png" width="320" alt="campaigns index"></a>
- `GET /campaigns/:slug` — redirects to `/programs`
- `GET /campaigns/:slug/overview` — `CampaignsController#overview` →
  `campaigns/overview.html.haml` — React widgets (`CampaignStats`,
  `WikidataOverviewStats`) embedded in a HAML page. `WikidataOverviewStats`
  renders whenever any course in the campaign has a `CourseStat` row
  containing `stats_hash['www.wikidata.org']` (it's the *combined* stats
  across the campaign's courses — see `CoursesPresenter#wikidata_stats`).
  <br><a href="screenshots/campaign_overview.png"><img src="screenshots/campaign_overview.png" width="320" alt="campaign overview (no wikidata activity)"></a>
  <a href="screenshots/campaign_overview_wikidata_sparse.png"><img src="screenshots/campaign_overview_wikidata_sparse.png" width="320" alt="campaign overview, wikidata stats (sparse)"></a>
  <a href="screenshots/campaign_overview_wikidata_rich.png"><img src="screenshots/campaign_overview_wikidata_rich.png" width="320" alt="campaign overview, wikidata stats (rich)"></a>
- `GET /campaigns/:slug/programs` — `CampaignsController#programs` →
  `campaigns/programs.html.haml` — React widgets embedded; main content is
  the list of courses in the campaign
  <br><a href="screenshots/campaign_programs.png"><img src="screenshots/campaign_programs.png" width="320" alt="campaign programs"></a>
- `GET /campaigns/:slug/articles` — `CampaignsController#articles` →
  `campaigns/articles.html.haml` — server-rendered table
  <br><a href="screenshots/campaign_articles.png"><img src="screenshots/campaign_articles.png" width="320" alt="campaign articles"></a>
- `GET /campaigns/:slug/users` — `CampaignsController#users` →
  `campaigns/users.html.haml` — server-rendered list
  <br><a href="screenshots/campaign_users.png"><img src="screenshots/campaign_users.png" width="320" alt="campaign users"></a>
- `GET /campaigns/:slug/alerts` — `CampaignsController#alerts` →
  `campaigns/alerts.html.haml` → React: `CampaignAlerts` (sub-route inside
  `Campaign`)
  <br><a href="screenshots/campaign_alerts.png"><img src="screenshots/campaign_alerts.png" width="320" alt="campaign alerts"></a>
- `GET /campaigns/:slug/ores_plot` — `CampaignsController#ores_plot` →
  `campaigns/ores_plot.html.haml` → React: `CampaignOresPlot` (sub-route
  inside `Campaign`)
  <br><a href="screenshots/campaign_ores_plot.png"><img src="screenshots/campaign_ores_plot.png" width="320" alt="campaign ores plot"></a>
- `GET /campaigns/:slug/edit` — `CampaignsController#edit` →
  `campaigns/edit.html.haml` — server-rendered edit form
  <br><a href="screenshots/campaign_edit.png"><img src="screenshots/campaign_edit.png" width="320" alt="campaign edit"></a>

## Tagged courses

Same shape as campaigns, narrower:

- `GET /tagged_courses/:tag` — redirects to `/programs`
- `GET /tagged_courses/:tag/programs` — `TaggedCoursesController#programs` →
  `tagged_courses/programs.html.haml` → React: `TaggedCoursesStats`
  <br><a href="screenshots/tagged_courses_programs.png"><img src="screenshots/tagged_courses_programs.png" width="320" alt="tagged courses programs"></a>
- `GET /tagged_courses/:tag/articles` — `TaggedCoursesController#articles` →
  `tagged_courses/articles.html.haml` — server-rendered
  <br><a href="screenshots/tagged_courses_articles.png"><img src="screenshots/tagged_courses_articles.png" width="320" alt="tagged courses articles"></a>
- `GET /tagged_courses/:tag/alerts` — `TaggedCoursesController#alerts` →
  `tagged_courses/alerts.html.haml` → React: `TaggedCourseAlerts`
  <br><a href="screenshots/tagged_courses_alerts.png"><img src="screenshots/tagged_courses_alerts.png" width="320" alt="tagged courses alerts"></a>

## Course listings

- `GET /active_courses` — `ActiveCoursesController#index` →
  `active_courses/index.html.haml` → React: `ActiveCoursesHandler`
  <br><a href="screenshots/active_courses.png"><img src="screenshots/active_courses.png" width="320" alt="active courses"></a>
- `GET /unsubmitted_courses` — `UnsubmittedCoursesController#index` →
  `unsubmitted_courses/index.html.haml` — server-rendered table
  <br><a href="screenshots/unsubmitted_courses.png"><img src="screenshots/unsubmitted_courses.png" width="320" alt="unsubmitted courses"></a>
- `GET /courses_by_wiki/:language.:project(.org)` — `CoursesByWikiController#show`
  → `courses_by_wiki/show.html.haml` → React: `CoursesByWikiHandler`
  <br><a href="screenshots/courses_by_wiki.png"><img src="screenshots/courses_by_wiki.png" width="320" alt="courses by wiki"></a>

## Article finder

- `GET /article_finder` — `ArticleFinderController#index` →
  `article_finder/index.html.haml` → React: `ArticleFinder`
  (Same component is also available inside the course page at
  `/courses/.../article_finder`.)
  <br><a href="screenshots/article_finder.png"><img src="screenshots/article_finder.png" width="320" alt="article finder"></a>
  <a href="screenshots/article_finder_results.png"><img src="screenshots/article_finder_results.png" width="320" alt="article finder with results"></a>
  <br>**Note:** `article_finder_results.png` is **not** byte-stable across
  runs — the React component fetches Wikipedia article stats (view counts,
  quality class) directly from the browser via `fetch`, which VCR/WebMock
  can't intercept. Expect the per-row numbers to drift day to day. Use a
  fuzz threshold (e.g. `compare -fuzz 5%`) when diffing this one.

## Training

Training has both server-rendered library/index pages and a React app for
walking through individual modules.

- `GET /training` — `TrainingController#index` → `training/index.html.haml` —
  server-rendered (library directory)
  <br><a href="screenshots/training_index.png"><img src="screenshots/training_index.png" width="320" alt="training index"></a>
- `GET /training/:library_id` — `TrainingController#show` →
  `training/show.html.haml` — server-rendered (library overview)
- `GET /training/:library_id/:module_id` — `TrainingController#training_module`
  → `training/training_module.html.haml` — server-rendered (module overview)
- `GET /training/:library_id/:module_id/*` — `TrainingController#slide_view` →
  `training/slide_view.html.haml` → React: `TrainingApp` (the slide viewer)
- `GET /training_module_drafts(/*any)` — `TrainingModuleDraftsController` →
  `training_module_drafts/index.html.haml` → React: `TrainingModuleComposer`
  <br><a href="screenshots/admin_training_module_drafts.png"><img src="screenshots/admin_training_module_drafts.png" width="320" alt="training module drafts"></a>

## Surveys

Almost entirely server-rendered (Rapidfire gem under the hood). Question
rendering, conditional logic, and progress stepping are jQuery-driven inside
a stripped-down `surveys_minimal` layout.

### Admin views

- `GET /surveys` — `SurveysController#index` → `surveys/index.html.haml` —
  server-rendered (admin list)
  <br><a href="screenshots/admin_surveys.png"><img src="screenshots/admin_surveys.png" width="320" alt="surveys index"></a>
- `GET /surveys/new` — server-rendered (new survey form)
  <br><a href="screenshots/admin_surveys_new.png"><img src="screenshots/admin_surveys_new.png" width="320" alt="surveys new"></a>
- `GET /surveys/:id/edit` — server-rendered
  <br><a href="screenshots/admin_survey_edit.png"><img src="screenshots/admin_survey_edit.png" width="320" alt="survey edit"></a>
- `GET /surveys/:id/question_group` — server-rendered (question-group editor)
  <br><a href="screenshots/admin_survey_question_group.png"><img src="screenshots/admin_survey_question_group.png" width="320" alt="survey question group"></a>
- `GET /surveys/:id/optout` — server-rendered (respondent opt-out flow)
- `GET /surveys/select_course/:id` — server-rendered (respondent course
  selection)
- `GET /surveys/results` — server-rendered (results index)
  <br><a href="screenshots/admin_surveys_results_index.png"><img src="screenshots/admin_surveys_results_index.png" width="320" alt="surveys results index"></a>
- `GET /survey/results/:id` — `SurveyResultsController#results` —
  server-rendered (individual survey results)
- `GET /survey/responses` — `SurveyResponsesController#index` —
  server-rendered
  <br><a href="screenshots/admin_survey_responses.png"><img src="screenshots/admin_survey_responses.png" width="320" alt="survey responses"></a>
- `GET /surveys/assignments`, `/new`, `/:id`, `/:id/edit` —
  `SurveyAssignmentsController` — server-rendered (admin: who gets the
  survey and when)
  <br><a href="screenshots/admin_survey_assignments.png"><img src="screenshots/admin_survey_assignments.png" width="320" alt="survey assignments"></a>
- Rapidfire mount under `/surveys/rapidfire/...` provides the
  question/question-group CRUD UI.

### Respondent view — `GET /surveys/:id`

A respondent reaches `/surveys/:id` via a notification (or a course
prompt). The survey reveals one question (or one matrix block) at a time,
with a progress bar across the top. Question types ship as separate
Rapidfire subclasses, each with its own input UI:

- **Intro panel** — survey name + intro text + Start button.
  <br><a href="screenshots/survey_intro.png"><img src="screenshots/survey_intro.png" width="320" alt="survey intro"></a>
- **Short text** — single-line input.
  <br><a href="screenshots/survey_short.png"><img src="screenshots/survey_short.png" width="320" alt="survey short text question"></a>
- **Long text** — multi-line textarea.
  <br><a href="screenshots/survey_long.png"><img src="screenshots/survey_long.png" width="320" alt="survey long text question"></a>
- **Radio** — single choice, one stacked button per option.
  <br><a href="screenshots/survey_radio.png"><img src="screenshots/survey_radio.png" width="320" alt="survey radio question"></a>
- **Checkbox** — multiple choice; "None of the above" is appended automatically.
  <br><a href="screenshots/survey_checkbox.png"><img src="screenshots/survey_checkbox.png" width="320" alt="survey checkbox question"></a>
- **Select** — dropdown.
  <br><a href="screenshots/survey_select.png"><img src="screenshots/survey_select.png" width="320" alt="survey select question"></a>
- **Numeric** — number input with optional min/max validation.
  <br><a href="screenshots/survey_numeric.png"><img src="screenshots/survey_numeric.png" width="320" alt="survey numeric question"></a>
- **RangeInput** — slider with min/max bounds and increment.
  <br><a href="screenshots/survey_range.png"><img src="screenshots/survey_range.png" width="320" alt="survey range slider question"></a>
- **course_data** — when the question's `course_data_type` is set, options come from the respondent's course (here: Articles).
  <br><a href="screenshots/survey_course_data_articles.png"><img src="screenshots/survey_course_data_articles.png" width="320" alt="survey course_data articles question"></a>
- **Matrix** — multiple Radio questions with `grouped: 1` collapse into a shared-options grid.
  <br><a href="screenshots/survey_matrix.png"><img src="screenshots/survey_matrix.png" width="320" alt="survey matrix question"></a>
- **Thanks panel** — shown after Submit Survey, with the configured `thanks` message.
  <br><a href="screenshots/survey_thanks.png"><img src="screenshots/survey_thanks.png" width="320" alt="survey thanks"></a>

## User profiles

- `GET /users/:username` — `UserProfilesController#show` →
  `user_profiles/show.html.haml` → React: `UserProfile`
  <br><a href="screenshots/user_profile.png"><img src="screenshots/user_profile.png" width="320" alt="user profile"></a>
- `GET /users` — `UsersController#index` → `users/index.html.haml` —
  server-rendered (admin lookup of users by ID)
  <br><a href="screenshots/admin_users_lookup.png"><img src="screenshots/admin_users_lookup.png" width="320" alt="users lookup"></a>

## Admin

The admin index is a HAML page of links. Most admin tools are individual
small HAML pages with forms; a few are full React apps.

- `GET /admin` — `AdminController#index` → `admin/index.html.haml` —
  server-rendered (link directory to all admin tools below)
  <br><a href="screenshots/admin_index.png"><img src="screenshots/admin_index.png" width="320" alt="admin index"></a>
- `GET /settings` — `SettingsController#index` → `settings/index.html.haml`
  → React: `SettingsHandler` (admin-list, special-users, etc. — these are
  React tabs/sub-views, not separate Rails routes)
  <br><a href="screenshots/admin_settings.png"><img src="screenshots/admin_settings.png" width="320" alt="settings"></a>
- `GET /alerts_list` — `AlertsListController#index` →
  `alerts_list/index.html.haml` → React: `AdminAlerts`
  <br><a href="screenshots/admin_alerts_list.png"><img src="screenshots/admin_alerts_list.png" width="320" alt="alerts list"></a>
- `GET /alerts_list/:id` — `AlertsListController#show` →
  `alerts_list/show.html.haml` — server-rendered
- `GET /ai_edit_alerts_stats/select_campaign` —
  `AiEditAlertsStatsController#select_campaign` — server-rendered (campaign
  picker)
  <br><a href="screenshots/admin_ai_edit_alerts_select.png"><img src="screenshots/admin_ai_edit_alerts_select.png" width="320" alt="ai edit alerts select"></a>
- `GET /ai_edit_alerts_stats/:campaign_slug` —
  `AiEditAlertsStatsController#index` →
  `ai_edit_alerts_stats/index.html.haml` → React: `AlertsStats`
- `GET /tickets/dashboard` — `TicketsController#dashboard` →
  `tickets/dashboard.html.haml` → React: `TicketsHandler`
  <br><a href="screenshots/admin_tickets_dashboard.png"><img src="screenshots/admin_tickets_dashboard.png" width="320" alt="tickets dashboard"></a>
- `GET /tickets/dashboard/:id` — same controller/template → React:
  `TicketShowHandler`
- `GET /recent-activity(/*any)` — `RecentActivityController#index` →
  `recent_activity/index.html.haml` → React: `RecentActivityHandler`
  (admin-only)
  <br><a href="screenshots/admin_recent_activity.png"><img src="screenshots/admin_recent_activity.png" width="320" alt="recent activity"></a>
- `GET /requested_accounts` — `RequestedAccountsController#index` —
  server-rendered (list)
  <br><a href="screenshots/admin_requested_accounts.png"><img src="screenshots/admin_requested_accounts.png" width="320" alt="requested accounts"></a>
- `GET /requested_accounts/:course_slug` —
  `RequestedAccountsController#show` — server-rendered
- `GET /requested_accounts_campaigns/:campaign_slug` —
  `RequestedAccountsCampaignsController#index` — server-rendered
- `GET /requested_accounts_campaigns/:campaign_slug/create` — same
  controller, `#create_accounts` — server-rendered
- `GET /mass_enrollment/:course_id` — `MassEnrollmentController#index` →
  `mass_enrollment/index.html.haml` — server-rendered (paste a list of
  usernames to enroll)
  <br><a href="screenshots/admin_mass_enrollment.png"><img src="screenshots/admin_mass_enrollment.png" width="320" alt="mass enrollment"></a>
- `GET /update_username` — `UpdateUsernameController#index` —
  server-rendered (admin tool to rename a user)
  <br><a href="screenshots/admin_update_username.png"><img src="screenshots/admin_update_username.png" width="320" alt="update username"></a>
- `GET /timeslice_duration` — `TimesliceDurationController#index` —
  server-rendered (form)
  <br><a href="screenshots/admin_timeslice_duration.png"><img src="screenshots/admin_timeslice_duration.png" width="320" alt="timeslice duration"></a>
- `GET /timeslice_duration/update` — `TimesliceDurationController#show` —
  server-rendered (results)
- `GET /mass_email/term_recap` — `MassEmailTermRecapController#index` —
  server-rendered (admin email tool)
  <br><a href="screenshots/admin_mass_email_term_recap.png"><img src="screenshots/admin_mass_email_term_recap.png" width="320" alt="mass email term recap"></a>
- `GET /revision_ai_scores_stats` — `RevisionAiScoresStatsController#index`
  → `revision_ai_scores_stats/index.html.haml` → React:
  `RevisionAiScoresStats`
  <br><a href="screenshots/admin_revision_ai_scores_stats.png"><img src="screenshots/admin_revision_ai_scores_stats.png" width="320" alt="revision ai scores stats"></a>
- `GET /revision_feedback` — `RevisionFeedbackController#index` →
  `revision_feedback/index.html.haml` — server-rendered
  <br><a href="screenshots/admin_revision_feedback.png"><img src="screenshots/admin_revision_feedback.png" width="320" alt="revision feedback"></a>
- `GET /ai_tools` — `AiToolsController#show` → `ai_tools/show.html.haml` —
  server-rendered (form + results)
  <br><a href="screenshots/admin_ai_tools.png"><img src="screenshots/admin_ai_tools.png" width="320" alt="ai tools"></a>
- `GET /status` — `SystemStatusController#index` →
  `system_status/index.html.haml` — server-rendered (queue + worker
  metrics)
  <br><a href="screenshots/admin_status.png"><img src="screenshots/admin_status.png" width="320" alt="system status"></a>
- `GET /mailer_previews` — `MailerPreviewsController#index` —
  server-rendered (public transparency page listing email templates;
  individual mailer-preview routes link out from here)
  <br><a href="screenshots/admin_mailer_previews.png"><img src="screenshots/admin_mailer_previews.png" width="320" alt="mailer previews"></a>
- `GET /styleguide` — `StyleguideController#index` — server-rendered design
  system reference
  <br><a href="screenshots/admin_styleguide.png"><img src="screenshots/admin_styleguide.png" width="320" alt="styleguide"></a>

## Analytics

- `GET /analytics(/*any)` — `AnalyticsController#index` →
  `analytics/index.html.haml` — server-rendered (forms with results)
  <br><a href="screenshots/admin_analytics.png"><img src="screenshots/admin_analytics.png" width="320" alt="analytics"></a>
- `GET /usage` — `AnalyticsController#usage` — server-rendered
  <br><a href="screenshots/admin_usage.png"><img src="screenshots/admin_usage.png" width="320" alt="usage"></a>

## Feedback

- `GET /feedback` — `FeedbackFormResponsesController#new` —
  server-rendered (user-facing form, shown on most pages via a sidebar
  link)
  <br><a href="screenshots/feedback_form.png"><img src="screenshots/feedback_form.png" width="320" alt="feedback form"></a>
- `GET /feedback/confirmation` — server-rendered
  <br><a href="screenshots/feedback_confirmation.png"><img src="screenshots/feedback_confirmation.png" width="320" alt="feedback confirmation"></a>
- `GET /feedback_form_responses` — admin list — server-rendered
  <br><a href="screenshots/admin_feedback_responses.png"><img src="screenshots/admin_feedback_responses.png" width="320" alt="feedback responses"></a>
- `GET /feedback_form_responses/:id` — admin show — server-rendered

## Error pages

- `GET /errors/file_not_found`, `/errors/unprocessable`,
  `/errors/internal_server_error`, `/errors/incorrect_passcode`,
  `/errors/login_error` — `ErrorsController` — server-rendered
- `GET /404`, `/422`, `/500` — same controller via the error matchers
  <br><a href="screenshots/error_404.png"><img src="screenshots/error_404.png" width="320" alt="404"></a>
  <a href="screenshots/error_500.png"><img src="screenshots/error_500.png" width="320" alt="500"></a>
  <a href="screenshots/error_login.png"><img src="screenshots/error_login.png" width="320" alt="login error"></a>

---

## Cross-cutting React components

These don't have their own routes but show up on many pages and are worth
knowing about when planning audits or refactors:

- `Confirm` — modal confirmation dialog
- `Modal` — generic modal wrapper used by Confirm and many others
- `CourseNavbar`, `CampaignNavbar` — tab bars
- `CourseAlerts`, `CampaignAlerts` — banner alerts
- `EnrollCard` — course enrollment modal
- `CampaignStats`, `CampaignStatsDownloadModal`, `WikidataOverviewStats`,
  `CampaignOresPlot` — campaign-page widgets
- `DatePicker` (wraps react-day-picker 7.x) — used everywhere dates are
  edited
- `CreatableInput` (wraps react-select 5.x) — used wherever a freeform
  combobox is needed
- `Notifications` — toast/notification queue (mounted globally)

## Stack notes

- React Router v6 throughout. Top-level routes in `util/routes.jsx`; many
  pages nest a second router (course, campaign, onboarding, training,
  recent-activity, settings, tickets, training-module-drafts).
- Redux + react-redux for shared state. Course, campaign, articles,
  assignments, users, and validations live in the store.
- React components are lazy-loaded via `React.lazy` and `Suspense` at the
  top level, so each major area splits into its own webpack chunk.
- Mailer preview routes and JSON endpoints are intentionally not listed
  here; this doc covers user-visible HTML pages only.
