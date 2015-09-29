# WikiEduDashboard

[![Build Status](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard.svg?branch=master)](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard)
[![Test Coverage](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/coverage.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)
[![Code Climate](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard/badges/gpa.svg)](https://codeclimate.com/github/WikiEducationFoundation/WikiEduDashboard)
[![Gemnasium](https://img.shields.io/gemnasium/WikiEducationFoundation/WikiEduDashboard.svg)](https://gemnasium.com/WikiEducationFoundation/WikiEduDashboard)

The WikiEdu Dashboard is a web application that provides data about Wikipedia educational assignments that use the course page system (the EducationProgram extension) on Wikipedia. This is a project of Wiki Education Foundation, developed in partnership with WINTR, intended for our education programs on English Wikipedia. To see it in action, visit [dashboard.wikiedu.org](http://dashboard.wikiedu.org).

## What it does

The Dashboard pulls information from the EducationProgram extension's Wikipedia API to identify which users are part of courses. It then gathers information about edits those users have made and articles they have edited, and creates a dashboard for each course intended to let instructors and others quickly see key information about the work of student editors. It also creates a global dashboard to see information about many courses at once.

 * The system shows information for based on list course IDs defined by a page on Wikipedia.
 * The system queries the liststudents api on English Wikipedia to get basic details about each course: who the students are, when the course starts and ends, and so on.
 * The system uses a set of endpoints on Wikimedia Labs (see [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)) to perform queries on a replica Wikipedia database, for information about articles and revisions related to the courses.
 * The system pulls page views (from [stats.grok.se](http://stats.grok.se)) for relevant articles on a daily basis.
 * The system pulls revision metadata from ores.wmflabs.org on a daily basis.

## Documentation
### Setup
- [Dashboard Setup](docs/setup.md)
- [OAuth Setup](docs/oauth.md)
- [Troubleshooting](docs/troubleshooting.md)

### Technology
- [Front end](docs/frontend.md)
- [Analytics Pipeline](docs/importers.md)

### Other
- [Contributing](docs/contributing.md)
- [Deployment](docs/deploy.md)
- [Tools & Integrations](docs/tools.md)
- [Model diagram](erd.pdf)
