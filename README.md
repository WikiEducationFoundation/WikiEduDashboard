WikiEduDashboard
================

[![Build Status](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard.svg?branch=master)](https://travis-ci.org/WikiEducationFoundation/WikiEduDashboard)

The WikiEdu Dashboard is a web application that provides data about Wikipedia educational assignments that use the course page system (the EducationProgram extension) on Wikipedia. This is a project of Wiki Education Foundation, developed in partnership with WINTR, intended for our education programs on English Wikipedia. To see it in action, visit [dashboard.wikiedu.org](http://dashboard.wikiedu.org).

What it does
---------------
The Dashboard pulls information from the EducationProgram extension's Wikipedia API to identify which users are part of courses. It then gathers information about edits those users have made and articles they have edited, and creates a dashboard for each course intended to let instructors and others quickly see key information about the work of student editors. It also creates a global dashboard to see information about many courses at once.

 * The system shows information for based on list course IDs defined by a page on Wikipedia.
 * The system queries the liststudents api on English Wikipedia to get basic details about each course: who the students are, when the course starts and ends, and so on.
 * The system uses a set of endpoints on Wikimedia Labs (see [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)) to perform queries on a replica Wikipedia database, for information about articles and revisions related to the courses.
 * The system pulls page views (from [stats.grok.se](http://stats.grok.se)) for relevant articles on a daily basis.

Contributing
---------------
#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

#### Tests
Tests reside in the `/spec` folder. Both unit and integration tests are driven by [RSpec](https://github.com/rspec/rspec).
* Write unit tests before building new features whenever possible. This project uses [RSpec](https://github.com/rspec/rspec) in conjuction with [SimpleCov](https://github.com/colszowka/simplecov) for unit testing. 
* Write integration tests for new interfaces. This project uses [Capybara](https://github.com/jnicklas/capybara) and [Capybara-webkit](https://github.com/thoughtbot/capybara-webkit) for integration testing.

Requirements
---------------
 * **Ruby (RVM recommended)**
 * **Node**
 * **NPM**
 * **Bower**

Project Setup
----------------

- Fork this repo, so that you can set it up for a new server.
- Clone the new WikiEduDashboard repo and enter that directory.
- Install Ruby 2.1.5 (RVM is recommended)
    - From the WikiEduDashboard directory, run the curl script from [rvm.io](https://rvm.io/)
    - Run the install command suggested by the script, something like `rvm install ruby-2.1.5`
- Install Node: [Node.js Installer](http://nodejs.org/)

- Install Gems:
    - $ `bundle install`

- Install NPM modules:
    - $ `npm install`

- Install Bower and Bower modules:
    - $ `sudo npm install bower -g`
    - $ `bower install`

- Add config files:
    - Save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively, in the `config` directory. Fill in your Wikipedia account login details in `application.yml` (for API access). The default settings in `database.yml` will suffice for a development environment.

#### Integrations

For error logging, we use [Sentry](https://github.com/getsentry/sentry). You'll need access to a Sentry server to use this functionality; add the Sentry DSN to `config/application.yml`.

For analytics (ie, tracking traffic), we use [Piwik](https://github.com/piwik/piwik). You need access to a Piwik server to use this funcationality; add the url and project id to `config/piwik.yml`.

Initialize
--------------
1. **Start Guard**

      $ `guard`

2. **Migrate the database**

      $ `rake db:migrate`

3. **Pull data from sources** (this could take a very long time)

      $ `rake batch:initialize`

Develop
------
1. **Start Zeus**

      $ `zeus start`

2. **Start Guard**

      $ `guard`

3. **Start Gulp to watch JS and CSS**

      $ `gulp`

4. The frontend is now visible at http://localhost:3000/

Deploy
------

For deployment, the Dashboard uses [Capistrano](https://en.wikipedia.org/wiki/Capistrano_%28software%29). This requires authentication with the server via SSH.

After pushing updates to repo (on Github), run the following command(s)
- Staging: `cap staging deploy` (This will deploy from the "master" branch)
- Production: `cap production deploy` (This will deploy from "production" branch)

To run rake tasks on a server via Capistrano, use "sake":
- $ `cap production sake task="batch:update_constantly"`

Set up a new production server
---------------

For detailed instructions on setting up a production server — specifically on a wmflabs virtual server, but the process will be similar for other infrastructure as well — see [WMFLABS_DEPLOYMENT](WMFLABS_DEPLOYMENT.md).
