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
