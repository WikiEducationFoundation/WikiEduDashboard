WikiEduDashboard
================

Dashboard application facilitating Wikiedu-powered courses

Requirements
---------------
 * **Ruby (RVM recommended)**
 * **Node**
 * **NPM**
 * **Bower**

Project Setup
----------------
1. **Install Gems**

      $ bundle install

2. **Install NPM modules**

      $ npm install

3. **Install Bower and Bower modules**

      $ npm install bower -g

      $ bower install

4. **Add config files**

      Save `application.example.yml` and `database.example.yml` as `application.yml` and `database.yml`, respectively. Fill in your Wikipedia account login details in `application.yml` (for API access). The default settings in `database.yml` will suffice for a development environment.

Initialization
--------------
1. **Start Guard**

      $ guard

2. **Migrate the database**

      $ rake db:migrate

3. **Pull data from sources** (this could take a very long time)

      $ rake batch:initialize

Develop
------
1. **Start Zeus**

      $ zeus start

2. **Start Guard**

      $ guard

3. **Start Gulp to watch JS and CSS**

      $ gulp

4. The frontend is now visible at http://localhost:3000/
