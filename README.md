WikiEduDashboard
================

The WikiEdu Dashboard is a web application that provides data about Wikipedia educational assignments that use the course page system (the EducationProgram extension) on Wikipedia. This is a project of Wiki Education Foundation, developed in partnership with WINTR, intended for our education programs on English Wikipedia. To see it in action, visit [dashboard.wikiedu.org](http://dashboard.wikiedu.org).

What it does
---------------
The Dashboard pulls information from the EducationProgram extension's Wikipedia API to identify which users are part of courses. It then gathers information about edits those users have have and articles they have edited, and creates a dashboard for each course intended to let instructors and others quickly see key information about the work of student editors. It also creates a global dashboard to see information about many courses at once.

 * The system shows information for based on list course IDs defined by a page on Wikipedia.
 * The system queries the liststudents api on English Wikipedia to get basic details about each course: who the students are, when the course starts and ends, and so on.
 * The system uses a set of endpoints on Wikimedia Labs (see [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools) to perform queries on a replica Wikipedia database, for information about articles and revisions related to the courses.
 * The system pulls page views (from [stats.grok.se](http://stats.grok.se)) for relevant articles on a daily basis.

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

      $ [sudo] npm install bower -g

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
