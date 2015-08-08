[Back to README](../README.md)

## Requirements
 * **Ruby (RVM recommended)**
 * **Node**
 * **NPM**
 * **Bower**

## Project Setup

- Fork this repo, so that you can set it up for a new server.
- Clone the new WikiEduDashboard repo and enter that directory.
- Make sure you are in the "sudo" group.
- Install Ruby 2.1.5 (RVM is recommended)
    - From the WikiEduDashboard directory, run the curl script from [rvm.io](https://rvm.io/)
    - `rvm install ruby-2.1.5`
- Install Node: `apt-get install nodejs npm`

- Install Gems:
    - $ `gem install bundler`
    - $ `bundle install`
    - If some gems fail to install, you may need to install some dependencies, such as: `libmysqlclient-dev libpq-dev libqtwebkit-dev`

- Install NPM modules:
    - $ `npm install`

- Install Bower and Bower modules:
    - $ `sudo npm install bower -g`
    - $ `bower install`

- Add config files:
    - Save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively, in the `config` directory. Fill in your Wikipedia account login details in `application.yml` (for API access). The default settings in `database.yml` will suffice for a development environment.

- Create mysql development and test database:
    - Install mysql-server and start a mysql command line
    - `CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - Grant access to these databases to your user.
    - `GRANT ALL ON dashboard.* TO <USER>@localhost identified by <PASSWORD>;`
    - `GRANT ALL ON dashboard_testing.* TO <USER>@localhost identified by <PASSWORD>;`

## Initialize
1. **Start Guard**
      $ `guard`

2. **Migrate the database**
      $ `rake db:migrate`
      
## Seed data (optional; this could take a very long time)

1. **Uncomment or add cohort URLs in `application.yml`** 

	`cohort_fall_2014: "Wikipedia:Education_program/Dashboard/Fall_2014_course_ids"`
	`cohort_spring_2015: "Wikipedia:Education_program/Dashboard/course_ids"`

2. **Pull data from sources**

      $ `rake batch:initialize`

## [Set up OAuth integration](oauth.md) (optional)

## Develop
1. **Start Zeus**

      $ `zeus start`

2. **Start Guard**

      $ `guard`

3. **Start Gulp to watch JS and CSS**

      $ `gulp`

4. The frontend is now visible at http://localhost:3000/

## Maintain

The Dashboard includes several rake tasks intended to keep the database synced with Wikipedia:
- Initialize: `rake batch:initialize` (Only to be run manually, initializes the database)
- Constant update: `rake batch:update_constantly` (Runs every 15 minutes by default)
- Daily update: `rake batch:update_daily` (Runs once a day by default)