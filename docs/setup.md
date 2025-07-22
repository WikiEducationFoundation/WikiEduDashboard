##### Contents
- [Script setup](#script-setup)
  - [Prerequisite](#prerequisite)
  - [Instructions](#instructions)
  - [Troubleshooting](#troubleshooting)
- [Manual setup](#manual-setup)
  - [TL;DR bare minimum version](#tldr-bare-minimum-version)
  - [Detailed instructions](#detailed-instructions)
  - [Initialize](#initialize)
- [Importing data and using the development environment](#importing-data-and-using-the-development-environment)
  - [Set up OAuth integration (optional — skip unless you are working on WikiEdits features)](#set-up-oauth-integration-optional--skip-unless-you-are-working-on-wikiedits-features)
  - [Populate example data](#populate-example-data)
  - [Develop](#develop)
  - [Design](#design)
  - [Hot Module Replacement](#hot-module-replacement)

[Back to README](../README.md)

# Script setup
We have a script to automate the process of setting up your developmental environment. Right now, it supports Debian-based systems(Debian, Ubuntu etc.), Fedora and MacOS.

For Windows, the easiest way to get an environment set up is to [use Ubuntu with WSL 2](./ubuntu_wsl_setup.md).

## Prerequisite
There are some basic requirements for the script to work:
- git (to clone the repository)
- node version 14 or newer
- python 3.5 or newer
- ruby 3.1.2
- apt (debian) or homebrew (MacOS)

## Instructions
- Clone the repository
- From the repository directory, run `python3 setup.py`
  - The python file checks for your operating system and runs the corresponding system dependent script
- The script will ask for your root password and MySQL passwords.
  - While installing MySQL, the MySQL installer might ask you to setup the root password
  - In case of MacOS systems, the MySQL root password will be blank if the installer doesn't ask you to setup one.
- Wait for the installation to complete
- If you face any errors, you can find the log for the script in setup directory by the name of log.txt

In case of any errors please post your error logs on: https://github.com/WikiEducationFoundation/WikiEduDashboard/issues/1709.
You can also contact us on slack for any further queries.

## Troubleshooting
- If you want to setup your own manual Database config(Advanced users)
  - First, create your manual config file, `config/database.yml` from the sample file provided, `config/database.example.yml`
  - Run the script
  - Run Migrations if needed.
- If you face issues related to MySQL default password on your system
  - Please confirm your Password for MySQL
  - Delete `config/Database.yml`
  - Run the script again.
- If you face the error that `Sorry! Your operating is not supported by this script`
  - You can try running the system dependent scripts from setup directory, according to your system
  - You can try manual installation
- If you're running Windows and experience `RUNAS ERROR`
  - Try running a command prompt session as administrator (via right click), and run the batch script in that window i.e., `win-setup.bat`

# Manual setup
## TL;DR bare minimum version
If you know your way around Rails, here's the very short version. Some additional requirements are necessary to make all the tests pass and all the features work, but this should be enough to stand up the app quickly.

1. Fork and clone our repo from https://github.com/WikiEducationFoundation/WikiEduDashboard.
2. **Install gems:** run `bundle install`
3. Copy `config/application.example.yml` to `config/application.yml` 
4. Copy `config/database.example.yml` to `config/database.yml`
5. Now **login into your database**
      *  Either create a new user using `CREATE USER 'wiki'@localhost IDENTIFIED BY 'wikiedu';`. Verify you created a new user using the command `SELECT User FROM mysql.user;`
      *  or update `database.yml` with valid credentials to connect to the database
6. Create a new database named as `dashboard` using the command `CREATE DATABASE dashboard;`
      * To verify whether your database was created, use the command `SHOW DATABASES;`
7. Run `rake db:migrate` to migrate all database tables.
8. Install yarn (modern)
9. Run `yarn` to download the required javascript packages
10. **Building assets:**
      * `yarn start` to built the development version
      * `yarn build` to generate the production version
11. (Recommended) Configure Git
      * `git config core.hooksPath .git-hooks` to recognize the .git-hooks directory as the hooks directory
      * `chmod +x .git-hooks/pre-commit` to make the pre-commit hook executable
12. Finally, start rails with `guard` or `rails s`and open http://localhost:3000 in a web browser.
13. Now, you're up and running!!

## Detailed instructions

- Pre-requisites for setup on OSX (Mac)
    - You will need to have xcode installed in order to have `git` on your machine.  If you run `git` and it is not there, you will be prompted to install xcode.
    - To install rvm, you'll first need a gpg utility. You can install the GPG Suite from gpgtools.org
    - Homebrew will install itself when you run the rvm install command, if you don't have it already.

- Pre-requisites for setup on Windows:
    - Install Git from [the official Windows package](https://git-scm.com/download/win)

- Fork our repo from https://github.com/WikiEducationFoundation/WikiEduDashboard..
- In the console, download a copy of your forked repo with `git clone https://github.com/your_username/WikiEduDashboard.git` where `your_username` is your GitHub username.
- Enter the new WikiEduDashboard directory with `cd WikiEduDashboard`.
- On OSX/Debian, make sure you are in the "sudo" group.
- Install Ruby 3.1.2 (RVM is documented here; rbenv also works fine.)
    - OSX/Debian:
       - From the WikiEduDashboard directory, run the curl script from [rvm.io](https://rvm.io/)
       - Use **rvm:** `rvm install 3.1.2` followed by `rvm use 3.1.2`
       - or use **rbenv:** `rbenv install 3.1.2` followed by `rbenv local 3.1.2`
    - Windows:
       - Use [RailsInstaller](http://railsinstaller.org/en)
       - Install [Ruby DevKit](https://github.com/oneclick/rubyinstaller/wiki/Development-Kit)
- Install Node:
  - Debian: `sudo apt install nodejs`
  - OSX: `brew install node` (this assumes you are using [homebrew](brew.sh))
  - Windows: [Download the installer](https://nodejs.org/)

- Create mysql development and test database:
    - Install mariadb-server (or mysql-server)
        - Debian: `sudo apt-get install -y mariadb-server libmariadb-dev`
        - OSX: `brew install mariadb`
        - Windows: Install [XAMPP](https://www.apachefriends.org/index.html)
    - Start a mysql command line:
        - Debian: `sudo mysql`
        - OSX: `brew services start mariadb` then `sudo mysql`
            (If you receive the error message: `Can't connect to local MySQL server through socket '/tmp/mysql.sock' (2)`
            You may have a permissions issue. Try executing: `sudo chown -R _mysql:mysql /usr/local/var/mysql` before restarting database server and logging in)
        - Windows: `C:\xampp\mysql\bin\mysql -u root`
    - `CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `exit`

- Install Gems:
    - $ `gem install bundler`
    - $ `bundle install`
    - If some gems fail to install, you may need to install some dependencies, such as: `libmysqlclient-dev libpq-dev libqtwebkit-dev`

- [Install Yarn Modern](https://yarnpkg.com/getting-started/install)

- Install node modules via Yarn:
    - $ `yarn`

- Install Pandoc
    - Debian: `sudo apt install pandoc`
    - See the Pandoc [installation guide](http://pandoc.org/installing.html) for your environment's specifics.
    - Only Pandoc itself is needed; no additional related components (eg, LaTeX) are required.

- Add config files:
    - Either save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively, in the `config` directory. The default settings in `database.yml` will suffice for a development environment.
    - Or you can copy `config/application.example.yml` to `config/application.yml` by running the command `cp config/application.example.yml config/application.yml`
    - and copy `config/database.example.yml` to `config/database.yml` by running the command `cp config/database.example.yml config/database.yml`

- Install Redis:
  - Debian: `sudo apt install redis-server`
  - OSX: `brew install redis`
  - Windows: Download [the Windows port](https://github.com/MSOpenTech/redis/releases) by the Microsoft Open Tech Group

- (Optional) Set up a [`post-merge`](https://git-scm.com/docs/githooks#_post_merge) hook to update all dependencies if `package.json` or `Gemfile` changes.
  - Copy `.git-hooks/pull-update-deps` to `.git/hooks/post-merge`

- (Recommended) Set up a [`pre-commit`](https://git-scm.com/docs/githooks#_pre-commit) hook to run linting before making a commit
  - `git config core.hooksPath .git-hooks` Configure Git to recognize the .git-hooks directory as the hooks directory
  - `chmod +x .git-hooks/pre-commit` Make the pre-commit hook executable
  


## Initialize
1. **Migrate the development and test databases**
  - $ `rake db:migrate`
  - $ `rake db:migrate RAILS_ENV=test`

# Importing data and using the development environment
## [Set up OAuth integration](oauth.md) (optional — skip unless you are working on WikiEdits features)

## Populate example data

Running these tasks will take several minutes, and should populate your database
with a few example events with editing activity.

1. **Create courses with users**
  - $ `rake dev:populate`
    - To populate your course with data, check [Populating a course with data.](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/master/docs/user_roles.md#populating-a-course-with-data)


2. **Import revision and upload data**
  - Start Sidekiq, or run updates via rails console.

## Develop
1. **Start Redis** (if not already running as daemon)
    - Redis is used by Sidekiq. Some features — especially related to making
    edits on Wikipedia — will not work when Redis is down. On a Linux-based system,
    it will probably be running as a daemon automatically after installation. On OSX,
    you may need to start it manually.

      $ `redis-server`

      OR, if you used homebrew to install redis:

      $ `redis-server /usr/local/etc/redis.conf`

2. **Start the server**

    - OSX/Debian: Use guard. This tool starts the rails development server (on localhost:3000).
    It also watches the files, and will automatically restart the server when rails files are
    changed, and it will automatically run corresponding test files when applicable.

      $ `guard`

    - Windows:

      $ `rails s`

3. **Compile assets**

    The `yarn start` command will build the project's javascripts and stylesheets(in lieu of the rails asset pipeline), and watch the assets directory, recompiling after changes to javascript, jsx and stylesheet files. Using `yarn build` instead will generate the minified production version of assets.

    You can also use `yarn hot` to enable HMR. [See more](#hot-module-replacement).

4. The frontend is now visible at http://localhost:3000/

5. Sign in and visit http://localhost:3000/campaigns to create a campaign.

6. To set up test users and data, see [User Roles](user_roles.md)

## Design

The living style guide illustrates many of the design building blocks of the dashboard, which you can use for creating new features: http://localhost:3000/styleguide

## Hot Module Replacement

For pages which are primarily rendered in react, you can use the hot module replacement feature of webpack. This allows you to edit a component and see its changes reflect in the browser without reloading the page. You can learn more about HMR [here](https://webpack.js.org/concepts/hot-module-replacement/)

To enable HMR, set `hot_loading` to `true` in `config/application.yml`. Next, run `yarn hot`.

With HMR, no files are written to the filesystem. Instead, the browser will ask the server for the latest version of the files, which serves the files in memory.

This also means that to run the test suite(which require the files to be present on the disk), you need to run `yarn build` instead.
