# Admin Guide for Program & Events Dashboard
The **Programs & Events Dashboard** ([outreachdashboard.wmflabs.org](https://outreachdashboard.wmflabs.org)) is a web application designed to support the global Wikimedia community in organizing various programs, including edit-a-thons, education initiatives, and other events. See the **[Source Code](https://github.com/WikiEducationFoundation/WikiEduDashboard/tree/wmflabs)** and **[Phabricator Project](https://phabricator.wikimedia.org/project/manage/1052/)** for more details.

This guide provides an overview of the **Program & Events Dashboard** infrastructure, detailing the servers, tools, and third-party dependencies that power the system. It also provides resources for managing and troubleshooting the system.

## Table of Contents
1. [Infrastructure Overview](#infrastructure-overview)
   - [Servers](#servers)
   - [Integrated Toolforge Tools](#integrated-toolforge-tools)
   - [Other Integrated APIs and Third-Party Dependencies](#other-integrated-apis-and-third-party-dependencies)
2. [Monitoring and Logs](#monitoring-and-logs)
   - [Toolforge](#toolforge)
   - [Cloud VPS](#cloud-vps)
3. [Troubleshooting](#troubleshooting)
   - [Web Server Issues](#web-server-issues)
   - [Database Issues](#database-issues)
   - [Data Dumps and Recovery](#data-dumps-and-recovery)
4. [More Resources](#more-resources)

## Infrastructure Overview
The **Program & Events Dashboard** is hosted within the **Wikimedia Cloud VPS** project [globaleducation](https://openstack-browser.toolforge.org/project/globaleducation), which provides the infrastructure for all servers, allowing the dashboard to run on virtual machines that are flexible and easily managed within Wikimedia Cloud. 

The dashboard relies on several core servers and external tools to function. These components ensure that different tasks are isolated to avoid bottlenecks and improve system performance.

### Servers
The dashboard operates on a distributed server architecture to handle web requests, process background jobs, and store application data. Each server is dedicated to specific roles, minimizing competition for resources and improving reliability by isolating potential bottlenecks and failures.

Below is a breakdown of the key servers and their roles within the infrastructure:

1. **Web Server** 
   - **`peony-web.globaleducation.eqiad1.wikimedia.cloud`**  
     - Hosts the main web application and core Sidekiq processes using **RVM (Ruby Version Manager)**, **Phusion Passenger**, and **Apache**.
     - **Capistrano** is used for deployments  
     - Sidekiq processes hosted:  
       - `sidekiq-default`: Manages frequently run tasks (e.g., adding courses to update queues).  
       - `sidekiq-constant`: Handles transactional jobs (e.g., wiki edits, email notifications).  
       - `sidekiq-daily`: Executes long-running daily update tasks.  

2. **Sidekiq Servers**: These dedicated servers handle the other Sidekiq processes to isolate bottlenecks and failures:  
   - **`peony-sidekiq.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-short` for short-running course updates.  
   - **`peony-sidekiq-medium.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-medium` for typical course updates.  
   - **`peony-sidekiq-3.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-long` for long-running course updates with higher queue latency.  

3. **Database Server**  
   - **`peony-database.globaleducation.eqiad1.wikimedia.cloud`**: Stores program, user, and revision data. It supports the dashboard’s data queries and updates.

4. **Redis Server**  
   - **`p-and-e-dashboard-redis.globaleducation.eqiad1.wikimedia.cloud`**: Stores all task (job) details and is shared across all Sidekiq processes for task queuing and caching.

### Integrated Toolforge Tools

- **[wikiedudashboard](https://toolsadmin.wikimedia.org/tools/id/wikiedudashboard)**  
  A collection of PHP endpoints used to retrieve revision and article data from Wikimedia Replica databases.  
  See [replica.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/replica.rb) for an example of its usage.  
  **[[Live Tool](https://replica-revision-tools.wmcloud.org/), [Source Code](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)]**

- **[Reference Counter API](https://toolsadmin.wikimedia.org/tools/id/reference-counter)**  
  Flask API to count the number of existing references in a specified revision ID for a Wiki. This API has two main endpoints to retrieve number of references for a given revision, one using [wikitext](https://gitlab.wikimedia.org/toolforge-repos/reference-counter#based-on-wikitext), the other [using HTML](https://gitlab.wikimedia.org/toolforge-repos/reference-counter#based-on-html).  
  See [reference_counter_api.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/reference_counter_api.rb) for an example of its usage.  
  **[[Live Tool](https://reference-counter.toolforge.org/), [Source Code](https://gitlab.wikimedia.org/toolforge-repos/reference-counter),  [Phabricator Documentation](https://phabricator.wikimedia.org/T352177)]**

- **[Suspected Plagiarism API](https://toolsadmin.wikimedia.org/tools/id/ruby-suspected-plagiarism)**  
  API for fetching recent suspected plagiarism detected by CopyPatrol and accessing Turnitin reports.  
  See [plagiabot_importer.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/importers/plagiabot_importer.rb) for an example of its usage.  
  **[[Live Tool](https://ruby-suspected-plagiarism.toolforge.org/), [Source Code](https://github.com/WikiEducationFoundation/ruby-suspected-plagiarism)]**

- **[Copypatrol](https://toolsadmin.wikimedia.org/tools/id/copypatrol)**  
  A plagiarism detection tool, that allows you to see recent Wikipedia edits that are flagged as possible copyright violations. It serves as the database for the ruby-suspected-plagiarism tool.  
  **[[Live Tool](https://copypatrol.wmcloud.org/en), [Source Code](https://github.com/wikimedia/CopyPatrol/), [Documentation](https://meta.wikimedia.org/wiki/CopyPatrol), [Phabricator Project](https://phabricator.wikimedia.org/project/profile/1638/)]**

- **[PagePile](https://toolsadmin.wikimedia.org/tools/id/pagepile)**  
  Manages static lists of Wiki pages. You can use a PetScan query (among other options) to create a PagePile, essentially creating a permanent snapshot of the PetScan query results. You can also create a PagePile from a simple one-per-line text list of article titles.  
  See [pagepile_scoping.jsx](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/course_creator/scoping_methods/pagepile_scoping.jsx) and [pagepile_api.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/pagepile_api.rb) for examples of its usage.  
  **[[Live Tool](https://pagepile.toolforge.org/), [Source Code](https://bitbucket.org/magnusmanske/pagepile/src/master/), [Documentation](https://pagepile.toolforge.org/howto.html)]**


### Other Integrated APIs and Third-Party Dependencies

- **[PetScan](https://petscan.wmcloud.org/)**  
    A powerful tool that can assemble lists of articles using a wide variety of data sources (including categories and templates, as well incoming and outgoing links, Wikidata relationships, and more). Users create a query on the PetScan website, which returns a PSID for that query, and that PSID is how the Dashboard connects to the PetScan API to get the list of articles. PetScan queries are dynamic; while the query for a given PSID cannot be modified, the results may change each time the the query is run, based on changes that happened on Wikipedia and Wikidata.  
    See [petscan_scoping.jsx](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/course_creator/scoping_methods/petscan_scoping.jsx) and [petscan_api.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/petscan_api.rb#L5) for examples of its usage.  
    **[[Source Code](https://github.com/magnusmanske/petscan_rs), [Documentation](https://meta.wikimedia.org/wiki/PetScan/en)]**

- **[WikiWho API](https://wikiwho-api.wmcloud.org/en/api/v1.0.0-beta/)**  
  Set of APIs to parse historical revisions of Wikipedia articles, providing detailed provenance of each token (word) in terms of who added, removed, or reintroduced it across different revisions.  
  See [`ArticleViewerAPI.js`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/utils/ArticleViewerAPI.js#L96) and the [`wikiwhoColorURL`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/utils/URLBuilder.js#L35) for examples of its usage.  
  **[[Source Code](https://github.com/wikimedia/wikiwho_api), [Documentation](https://wikiwho-api.wmcloud.org/gesis_home)]**

- **[WhoColor API](https://wikiwho-api.wmcloud.org/en/whocolor/v1.0.0-beta/)**  
  Set of APIs built on top of the WikiWho API that allow for the visualization of authorship data by color-coding tokens in the text based on their original authors. The dashboard employs this to show authorship data on its dashboard for students.  
   **[[Source Code](https://github.com/wikimedia/wikiwho_api), [Documentation](https://wikiwho-api.wmcloud.org/gesis_home)]**

- **[WikidataDiffAnalyzer](https://github.com/WikiEducationFoundation/wikidata-diff-analyzer)**  
   Ruby gem for analyzing differences between revisions.  
   See [update_wikidata_stats.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/services/update_wikidata_stats.rb#L91) for an example of its usage.  
   **[[Source Code and Documentation](https://github.com/WikiEducationFoundation/wikidata-diff-analyzer)]**

- **[Liftwing API](https://api.wikimedia.org/wiki/Lift_Wing_API/Reference)**  
  Makes predictions about pages and edits using machine learning. The dashboard uses this API to fetch items and article quality data.  
  See [article_finder_action.js](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/actions/article_finder_action.js#L18) and [lift_wing_api.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/lift_wing_api.rb#L8) for examples of its usage.  
  **[[Source Code](https://gerrit.wikimedia.org/g/machinelearning/liftwing/), [Documentation](https://api.wikimedia.org/wiki/Lift_Wing_API), [Phabricator Project](https://phabricator.wikimedia.org/project/profile/5020/)]**

## Monitoring and Logs

#### Toolforge
To view Kubernetes namespace details for a Toolforge tool, go to https://k8s-status.toolforge.org/namespaces/tool-toolName/, replacing `toolName` with the name of the tool.

#### Cloud VPS
- [Grafana](https://grafana.wmcloud.org/d/0g9N-7pVz/cloud-vps-project-board?orgId=1&var-project=globaleducation)
- [Server Admin Logs (SAL)](https://sal.toolforge.org/globaleducation)
- [Alerts](https://prometheus-alerts.wmcloud.org/?q=%40state%3Dactive&q=project%3Dglobaleducation)
- [Puppet agent logs for the globaleducation project](https://grafana.wmcloud.org/d/SQM7MJZSz/cloud-vps-puppet-agents?orgId=1&var-project=globaleducation&from=now-2d&to=now) 

## Troubleshooting

### Web Server Issues
- **Internal Server Error**: Restart the web server.  
- **Unresponsive Web Service**:  
  - Usually caused by high-activity events or surges in ongoing activity, leading to system overload.  
    - **Solution**: Reboot the VM (instance) running the web server.  
    - The web service typically recovers within a few hours.  

### Database Issues
- **Full Disk**: Free up space by deleting temporary tables.  
- **High-Edit / Long Courses Causing Errors**:  
  - Consider turning off the 'long' and 'very_long_update' queues.   
- **Stuck Transactions**: If results in the Rails server becoming unresponsive, restart MySQL.  
- **Database Errors**:  
  - Verify that the app and database server versions are compatible.  

### Data Dumps and Recovery
- **Performing a Dump for a table**:  
  1. Put the database in `innodb_force_recovery=1` mode. 
        - Note: `OPTIMIZE TABLE revisions;` cannot run in recovery mode because the database is read-only.  
  2. Start the dump process.  
  3. Once the dump is complete, drop the table.  
  4. Remove the database from recovery mode and restore the table.  

Issues could also be caused by maintenance or outages in third-party dependencies or other services stated above.

## More Resources
- [Toolforge Documentation](https://wikitech.wikimedia.org/wiki/Help:Toolforge)
- [Cloud VPS Documentation](https://wikitech.wikimedia.org/wiki/Help:Cloud_VPS)
- [Cloud VPS Admin Documentation](https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin)
- [Details of most recent P&E server update](https://github.com/WikiEducationFoundation/WikiEduDashboard/commit/df271f1c54fd0520e42445fcc88f19b6d03a603b#diff-f8eaa8feeef99c2b098e875ccdace93998b84eeb4110dc9f49b1327df7d96e21)
