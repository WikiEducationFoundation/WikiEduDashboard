# Wiki Education Dashboard

[![Build Status](https://travis-ci.com/WikiEducationFoundation/WikiEduDashboard.svg?branch=master)](https://travis-ci.com/WikiEducationFoundation/WikiEduDashboard)
[![Test Coverage](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/coverage.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)
[![Code Climate](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/gpa.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)
[![Open Source Helpers](https://www.codetriage.com/wikieducationfoundation/wikiedudashboard/badges/users.svg)](https://www.codetriage.com/wikieducationfoundation/wikiedudashboard)

The Wiki Education Dashboard is a web application that supports Wikipedia education assignments, edit-a-thons, and other editing projects. It provides data and course management features for groups of editors — instructors, students, and others — who are working on Wikipedia, Wikidata, and other Wikimedia wikis. Users log in with their Wikipedia accounts (through OAuth) and allow the Dashboard to make edits on their behalf. The Dashboard automates many of the standard elements of organizing and participating in a Wikipedia classroom assignment, edit-a-thon, or other wiki contribution campaign.

The Dashboard code runs two main sites: the Wiki Education Dashboard — [dashboard.wikiedu.org](https://dashboard.wikiedu.org) — and the Wikimedia Programs & Events Dashboard — [outreachdashboard.wmflabs.org](https://outreachdashboard.wmflabs.org). dashboard.wikiedu.org is used for Wiki Education programs, primarily focused on higher education in the United States and Canada. outreachdashboard.wmflabs.org is for the global Wikimedia community to organize all kinds of programs, including edit-a-thons, education programs, and other events.

This is a project of [Wiki Education](https://wikiedu.org).

## What it does

The Dashboard allows instructors or program leaders to create a "course" page, which participants can join. It then gathers information about edits those users have made and articles they have edited, and creates a dashboard for each course intended to let instructors and others quickly see key information about the work of student editors. It also creates a global dashboard to see information about many courses at once.

Overview:
 * Uses a set of endpoints on Wikimedia Labs (see [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)) and the Wikipedia API to get information about articles and revisions related to the courses
 * Pulls page views (from the [Wikimedia pageviews API](https://wikimedia.org/api/rest_v1/#!/Pageviews_data/get_metrics_pageviews)) for relevant articles on a daily basis
 * Pulls revision metadata from ores.wikimedia.org
 * Provides training modules with content pulled from wiki pages on meta.wikimedia.org
 * ...and much more

## Contribute!

This project welcomes contributions, and we try to be as newbie-friendly as possible. Check out [the CONTRIBUTING file](CONTRIBUTING.md) for more details.

### Setup
- [Setting up a development environment](docs/setup.md)
- [Getting data and switching configurations](docs/user_roles.md)
- [Troubleshooting](docs/troubleshooting.md)

### Technology overview
- Backend - Ruby on Rails, with Sidekiq for background jobs and data updates
- [Front end](docs/frontend.md) - mostly built with React.js and Redux, with some server-rendered Ruby template (haml)
- [Analytics Pipeline](docs/importers.md)
- [Testing](docs/testing.md) - mainly Rspec, including browser-based feature specs

### Other
- [Contributing](CONTRIBUTING.md)
- [Outreachy & Google Summer of Code](docs/students_and_interns.md)
- [Development Process outline](docs/dev_process.md)
- [Interface strings & Internationalization](docs/i18n.md)
- [OAuth setup](docs/oauth.md)
- [Deployment](docs/deploy.md)
- [Admin Guide](docs/admin_guide.md) - Overview of the Dashboard infrastructure, including servers, tools, dependencies, and troubleshooting resources.
- [Tools & Integrations](docs/tools.md)
- [Using Docker for development](docs/docker.md)
- [Model diagram](erd.pdf)

### Translation
Translations for the Wiki Education Dashboard interface are handled through [translatewiki.net](https://translatewiki.net/wiki/Translating:Wiki_Ed_Dashboard).

### Code of Conduct
This project is part of the Wikimedia technical ecosystem and follows the [Wikimedia Code of Conduct](https://www.mediawiki.org/wiki/Code_of_Conduct).
