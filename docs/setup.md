[Back to README](../README.md)

## Requirements
 * **Ruby (RVM recommended)**
 * **Node**
 * **NPM**
 * **Bower**

## Project Setup

- Pre-requisites for setup on OSX (Mac)
    - You will need to have xcode installed in order to have `git` on your machine.  If you run `git` and it is not there, you will be prompted to install xcode.
    - To install rvm, you'll first need a gpg utility. You can install the GPG Suite from gpgtools.org
    - Homebrew will install itself when you run the rvm install command, if you don't have it already.

- Pre-requisites for setup on Windows:
    - Install Git from [the official Windows package](https://git-scm.com/download/win)

- Fork this repo, so that you can make changes and push them freely to GitHub.
- Clone the new WikiEduDashboard repo and enter that directory.
- On OSX/Debian, make sure you are in the "sudo" group.
- Install Ruby 2.3.1 (RVM is recommended)
    - OSX/Debian:
       - From the WikiEduDashboard directory, run the curl script from [rvm.io](https://rvm.io/)
       - `rvm install ruby-2.3.1`
    - Windows:
       - Use [RailsInstaller](http://railsinstaller.org/en)
- Install Node:
  - Debian: `apt install nodejs npm`
  - OSX: `brew install node` (this assumes you are using [homebrew](brew.sh))
  - Windows: [Download the installer](https://nodejs.org/)

- Install Gems:
    - $ `gem install bundler`
    - $ `bundle install`
    - If some gems fail to install, you may need to install some dependencies, such as: `libmysqlclient-dev libpq-dev libqtwebkit-dev`

- Install NPM modules via Yarn:
    - $ `sudo npm install yarn -g`
    - $ `yarn`

- Install PhantomJS:
    - $ `sudo npm install -g phantomjs-prebuilt`

- Install Bower and Bower modules:
    - $ `sudo npm install bower -g`
    - $ `bower install`

- Install Pandoc
    - See the Pandoc [installation guide](http://pandoc.org/installing.html) for your environment's specifics.
    - Only Pandoc itself is needed; no additional related components (eg, LaTeX) are required.

- Add config files:
    - Save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively, in the `config` directory. The default settings in `database.yml` will suffice for a development environment.

- Create mysql development and test database:
    - Install mysql-server
        - Debian: `sudo apt-get install mysql-server`
        - OSX: `brew install mysql`
        - Windows: Install [XAMPP](https://www.apachefriends.org/index.html)
    - Start a mysql command line:
        - OSX/Debian: `sudo mysql`
        - Windows: `C:\xampp\mysql\bin\mysql -u root`
    - `CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `exit`

- Install Redis:
  - Debian: `sudo apt-get install redis-server`
  - OSX: `brew install redis`
  - Windows: Download [the Windows port](https://github.com/MSOpenTech/redis/releases) by the Microsoft Open Tech Group

- Install Gulp (if not already installed)
  - `sudo npm install -g gulp-cli`

## Initialize
1. **Migrate the development and test databases**
      $ `rake db:migrate`
      $ `rake db:migrate RAILS_ENV=test`

2. **Create the campaigns specified in `application.yml`**
      $ `rake campaign:add_campaigns`

## [Set up OAuth integration](oauth.md) (optional — skip unless you are working on WikiEdits features)

## Develop
1. **Start Zeus (optional)**
    - Zeus (not available on Windows) is a tool to restart Rails services more
    quickly after files are changed.

      $ `zeus start`

2. **Start Redis** (if not already running as daemon)
    - Redis is used by Sidekiq. Some features — especially related to making
    edits on Wikipedia — will not work when Redis is down. On a Linux-based system,
    it will probably be running as a daemon automatically after installation. On OSX,
    you may need to start it manually.

      $ `redis-server`

3. **Start the server**

    - OSX/Debian: Use guard. This tool starts the rails development server (on localhost:3000).
    It also watches the files, and will automatically restart the server when rails files are
    changed, and it will automatically run corresponding test files when applicable.

      $ `guard`

    - Windows:

      $ `rails s`

4. **Start Gulp to compile assets**
    - The default gulp command will build the project's javascripts and stylesheets
    (in lieu of the rails asset pipeline), and watch the assets directory, recompiling
    after changes to javascript, jsx and stylesheet files. Using `gulp build` instead
    will generate the minified production version of assets.

      $ `gulp`

5. The frontend is now visible at http://localhost:3000/

6. To set up test users and data, see [User Roles](user_roles.md)

## Design

The living style guide illustrates many of the design building blocks of the dashboard, which you can use for creating new features: http://localhost:3000/styleguide

## Maintain

The Dashboard includes several rake tasks intended to keep the database synced with Wikipedia:
- Initialize: `rake batch:initialize` (Only to be run manually, initializes the database)
- Constant update: `rake batch:update_constantly` (Runs every 15 minutes by default)
- Daily update: `rake batch:update_daily` (Runs once a day by default)
