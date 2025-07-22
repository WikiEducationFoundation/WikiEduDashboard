[Back to README](../README.md)

## Admin Guide for Program & Events Dashboard

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
   - **`peony-sidekiq.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-long` for long-running course updates with higher queue latency.    
   - **`peony-sidekiq-medium.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-medium` for typical course updates.  
   - **`peony-sidekiq-3.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-short` for short-running course updates.  

3. **Database Server**  
   - **`peony-database.globaleducation.eqiad1.wikimedia.cloud`**: Stores program, user, and revision data. It supports the dashboard’s data queries and updates.

4. **Redis Server**  
   - **`p-and-e-dashboard-redis.globaleducation.eqiad1.wikimedia.cloud`**: Stores all task (job) details and is shared across all Sidekiq processes for task queuing and caching.

### Integrated Toolforge Tools

- **[wikiedudashboard](https://toolsadmin.wikimedia.org/tools/id/wikiedudashboard)**  
  The Dashboard uses this tool's PHP endpoints to query Wikimedia Replica databases for detailed revision and article data. The specific replica database the tool connects to is dependent on the wiki being queried. These endpoints support features like retrieving user contributions, identifying existing articles or revisions, and checking for deleted content. For example, the Dashboard uses the `/revisions.php` endpoint to fetch revisions by specific users within a time range, and `/articles.php` to verify the existence of articles or revisions. See [replica.rb](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/replica.rb) for implementation details.  

  **[[Live Tool](https://replica-revision-tools.wmcloud.org/), [Source Code](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)]**  

- **[Reference Counter API](https://toolsadmin.wikimedia.org/tools/id/reference-counter)**  
  The Reference Counter API is used to retrieve the number of references in a specified revision ID from a Wiki. The Dashboard interacts with the API through the [`ReferenceCounterApi`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/reference_counter_api.rb) class, which handles requests for reference counts by revision ID and processes multiple revisions in batch. It's important to note that the `ReferenceCounterApi` class and the `reference-counter` Toolforge API do not support Wikidata, as it uses a different method for calculating references.      

  **[[Live Tool](https://reference-counter.toolforge.org/), [Source Code](https://gitlab.wikimedia.org/toolforge-repos/reference-counter),  [Phabricator Documentation](https://phabricator.wikimedia.org/T352177)]**

- **[Suspected Plagiarism API](https://toolsadmin.wikimedia.org/tools/id/ruby-suspected-plagiarism)**  
  This API is used to detect and report suspected plagiarism in course-related content. It leverages CopyPatrol to detect instances of potential plagiarism by comparing revisions of Wikipedia articles. The API then retrieves data on suspected plagiarism, which includes information such as the revision ID, the user responsible, and the article involved. The [`PlagiabotImporter`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/importers/plagiabot_importer.rb) class uses this data to identify recent instances of suspected plagiarism and match them with relevant revisions in the Dashboard's database. If a new case is found, an alert is generated for suspected plagiarism in course materials and sent to content experts for review.  

  **[[Live Tool](https://ruby-suspected-plagiarism.toolforge.org/), [Source Code](https://github.com/WikiEducationFoundation/ruby-suspected-plagiarism)]**

- **[Copypatrol](https://toolsadmin.wikimedia.org/tools/id/copypatrol)**  
  A plagiarism detection tool, that allows you to see recent Wikipedia edits that are flagged as possible copyright violations. It is responsible for detecting instances of potential plagiarism by comparing revisions of Wikipedia articles.  

  **[[Live Tool](https://copypatrol.wmcloud.org/en), [Source Code](https://github.com/wikimedia/CopyPatrol/), [Documentation](https://meta.wikimedia.org/wiki/CopyPatrol), [Phabricator Project](https://phabricator.wikimedia.org/project/profile/1638/)]**

- **[PagePile](https://toolsadmin.wikimedia.org/tools/id/pagepile)**  
  PagePile manages static lists of Wiki pages. The Dashboard utilizes it to fetch a permanent snapshot of article titles through PagePile IDs or URLs. This is integrated into the course creation process, where users can input PagePile IDs or URLs to define a set of articles for the course. The [`PagePileApi`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/pagepile_api.rb) class is responsible for retrieving page titles from PagePile, ensuring the category's wiki is consistent with the PagePile data, and updating the system with the retrieved titles. The data is then used to scope course materials to specific articles - see [pagepile_scoping.jsx](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/course_creator/scoping_methods/pagepile_scoping.jsx).  

  **[[Live Tool](https://pagepile.toolforge.org/), [Source Code](https://bitbucket.org/magnusmanske/pagepile/src/master/), [Documentation](https://pagepile.toolforge.org/howto.html)]**


### Other Integrated APIs and Third-Party Dependencies

- **[PetScan](https://petscan.wmcloud.org/)**  
  The PetScan API is used in the Dashboard to integrate dynamic lists of articles based on user-defined queries. Users can enter PetScan IDs (PSIDs) or URLs to fetch a list of articles relevant to a course. The [`PetScanApi`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/petscan_api.rb#L5) class handles retrieving the list of page titles associated with a given PSID by querying PetScan's API. This data is used for scoping course materials to specific sets of articles - see [petscan_scoping.jsx](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/course_creator/scoping_methods/petscan_scoping.jsx), ensuring the Dashboard reflects the most up-to-date information from PetScan queries. The system ensures proper error handling for invalid or unreachable PSIDs to avoid disrupting the course creation process.  

  **[[Source Code](https://github.com/magnusmanske/petscan_rs), [Documentation](https://meta.wikimedia.org/wiki/PetScan/en)]**

- **[WikiWho API](https://wikiwho-api.wmcloud.org/en/api/v1.0.0-beta/)**  
  The WikiWho API is used in the Dashboard to parse historical revisions of Wikipedia articles and track the provenance of each word in the article. This data is particularly useful for displaying authorship information, such as identifying who added, removed, or reintroduced specific tokens (words) across different revisions. The [`URLBuilder`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/utils/URLBuilder.js#L35) class constructs the necessary URLs to interact with the WikiWho API, allowing the Dashboard to fetch parsed article data and token-level authorship highlights. This data is then used in the [`ArticleViewer`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/utils/ArticleViewerAPI.js#L96) component to enhance the display of articles by showing detailed authorship information, providing insights into the contributions of different editors over time.    

  **[[Source Code](https://github.com/wikimedia/wikiwho_api), [Documentation](https://wikiwho-api.wmcloud.org/gesis_home)]**

- **[WhoColor API](https://wikiwho-api.wmcloud.org/en/whocolor/v1.0.0-beta/)**  
  The WhoColor API is used in the Dashboard to add color-coding to the authorship data provided by the WikiWho API. It enhances the parsed article revisions by highlighting each token (word) with a color corresponding to its original author, making it easier to visualize contributions. The Dashboard processes this color-coded data by using the [`highlightAuthors`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/containers/ArticleViewer.jsx#L163) function, which replaces the span elements in the HTML with styled versions that include user-specific color classes. This allows the [`ArticleViewer`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/components/common/ArticleViewer/utils/ArticleViewerAPI.js#L96) component to display the article text with visual cues, highlighting which user contributed each part of the article, helping quick identification of the contributions of different authors.  

   **[[Source Code](https://github.com/wikimedia/wikiwho_api), [Documentation](https://wikiwho-api.wmcloud.org/gesis_home)]**

- **[WikidataDiffAnalyzer](https://github.com/WikiEducationFoundation/wikidata-diff-analyzer)**  
   The WikidataDiffAnalyzer gem is used to analyze differences between Wikidata revisions. It is utilized by the [`update_wikidata_stats.rb`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/services/update_wikidata_stats.rb#L91) service to process a list of revision IDs and determine the changes made between them, such as diffs added, removed, or changed claims, references, and labels. The results of the analysis are serialized and stored in the summary field of Wikidata revisions, providing detailed statistics about the nature of the edits. This enables the Dashboard to track and display revision-level changes.

   **[[Source Code and Documentation](https://github.com/WikiEducationFoundation/wikidata-diff-analyzer)]**

- **[Liftwing API](https://api.wikimedia.org/wiki/Lift_Wing_API/Reference)**  
  The Liftwing API is used to fetch article quality and item quality data by making predictions about pages and edits using machine learning models. The Dashboard interacts with this API to assess the quality of articles and revisions, utilizing the [`LiftWingApi`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/lib/lift_wing_api.rb#L8) service to retrieve scores and features associated with each revision. The [`article_finder_action.js`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/actions/article_finder_action.js#L18) class is responsible for fetching and processing article data. It takes the revision IDs from fetched revision data and sends them to the LiftWing API for processing by calling the [`fetchPageRevisionScore`](https://github.com/WikiEducationFoundation/WikiEduDashboard/blob/wmflabs/app/assets/javascripts/actions/article_finder_action.js#L180) function. The LiftWing API then processes the revision data and returns the quality scores for the articles.  

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
