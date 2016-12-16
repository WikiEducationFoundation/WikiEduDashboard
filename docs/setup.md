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

- Fork this repo, so that you can make changes and push them freely to GitHub.
- Clone the new WikiEduDashboard repo and enter that directory.
- Make sure you are in the "sudo" group.
- Install Ruby 2.3.1 (RVM is recommended)
    - From the WikiEduDashboard directory, run the curl script from [rvm.io](https://rvm.io/)
    - `rvm install ruby-2.3.1`
- Install Node:
  - Debian: `apt install nodejs npm`
  - OSX: `brew install node` (this assumes you are using [homebrew](brew.sh))

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
    - Start a mysql command line: `sudo mysql`
    - `CREATE DATABASE dashboard DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`
    - `CREATE DATABASE dashboard_testing DEFAULT CHARACTER SET utf8 DEFAULT COLLATE utf8_general_ci;`

- Install Redis:
  - Debian: `sudo apt-get install redis-server`
  - OSX: `brew install redis`

- Install Gulp (if not already installed)
  - `sudo npm install --global gulp-cli`

## Initialize
1. **Migrate the database**
      $ `rake db:migrate`

2. **Create the campaigns specified in `application.yml`**
      $ `rake campaign:add_campaigns`

## [Set up OAuth integration](oauth.md) (optional — skip unless you are working on WikiEdits features)

## Develop
1. **Start Zeus**

      $ `zeus start`

2. **Start Guard**

      $ `guard`

3. **Start Gulp to watch JS and CSS**

      $ `gulp`
if you are getting message "Error: EACCES: permission denied, open '/home/rlot/.babel.json'", use 
      $ `BABEL_DISABLE_CACHE=1 gulp`

4. The frontend is now visible at http://localhost:3000/

5. To set up test users and data, see [User Roles](user_roles.md)

## Maintain

The Dashboard includes several rake tasks intended to keep the database synced with Wikipedia:
- Initialize: `rake batch:initialize` (Only to be run manually, initializes the database)
- Constant update: `rake batch:update_constantly` (Runs every 15 minutes by default)
- Daily update: `rake batch:update_daily` (Runs once a day by default)
