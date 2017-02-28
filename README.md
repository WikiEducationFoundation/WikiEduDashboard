# Wiki Ed Dashboard

[![Build Status](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard.svg?branch=master)](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard)
[![Test Coverage](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/coverage.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)
[![Code Climate](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/gpa.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)

The Wiki Ed Dashboard is a web application that supports Wikipedia education assignments, provides data and course management features for groups of Wikipedia users — instructors, students, and others — who are working on a common Wikipedia project. Users log in with their Wikipedia accounts (through OAuth) and allow the dashboard to make edits on their behalf. The dashboard automates many of the standard elements of organizing and participating in a Wikipedia classroom assignment.

The dashboard code runs two main projects: the Wiki Education Foundation Dashboard — [dashboard.wikiedu.org](https://dashboard.wikiedu.org) — and the Wikimedia Programs & Events Dashboard — [outreachdashboard.wmflabs.org](https://outreachdashboard.wmflabs.org). dashboard.wikiedu.org is used for Wiki Education Foundation programs, primarily focused on higher education in the United States and Canada. outreachdashboard.wmflabs.org is for the global Wikimedia community to organize all kinds of programs, including edit-a-thons, education programs, and other events.

This is a project of [Wiki Education Foundation](https://wikiedu.org).

## What it does

The Dashboard allows instructors to create a course page, which students can join. It then gathers information about edits those users have made and articles they have edited, and creates a dashboard for each course intended to let instructors and others quickly see key information about the work of student editors. It also creates a global dashboard to see information about many courses at once.

 * The system shows information for based on list course IDs defined by a page on Wikipedia.
 * The system uses a set of endpoints on Wikimedia Labs (see [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)) and the Wikipedia API to perform queries on a replica Wikipedia database, for information about articles and revisions related to the courses.
 * The system pulls page views (from the [Wikimedia pageviews API](https://wikimedia.org/api/rest_v1/#!/Pageviews_data/get_metrics_pageviews)) for relevant articles on a daily basis.
 * The system pulls revision metadata from ores.wikimedia.org on a daily basis.

## Documentation
### Setup
- [Dashboard Setup](docs/setup.md)
- [Using the Dashboard in development](docs/user_roles.md)
- [OAuth Setup](docs/oauth.md)
- [Troubleshooting](docs/troubleshooting.md)

### Technology
- [Front end](docs/frontend.md)
- [Analytics Pipeline](docs/importers.md)
- [Testing](docs/testing.md)

### Other
- [Contributing](CONTRIBUTING.md)
- [Development Process for Agile Ventures members](docs/dev_process.md)
- [Interface strings & Internationalization](docs/i18n.md)
- [Deployment](docs/deploy.md)
- [Tools & Integrations](docs/tools.md)
- [Model diagram](erd.pdf)
