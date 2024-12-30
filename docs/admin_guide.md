# Admin Guide for Program & Events Dashboard

This guide provides an overview of the Program & Events Dashboard. It also offers resources for managing and troubleshooting the system.

## Table of Contents
1. [Overview](#overview)
2. [Monitoring and Logs](#monitoring-and-logs)
   - [Toolforge](#toolforge)
   - [Cloud VPS](#cloud-vps)
3. [Troubleshooting](#troubleshooting)
    - [Web Server Issues](#web-server-issues)
    - [Database Issues](#database-issues)
    - [Data Dumps and Recovery](#data-dumps-and-recovery)
4. [More Resources](#more-resources)

## Overview

The **Programs & Events Dashboard** ([outreachdashboard.wmflabs.org](https://outreachdashboard.wmflabs.org)) is a web application designed to support the global Wikimedia community in organizing various programs, including edit-a-thons, education initiatives, and other events. **[Source Code](https://github.com/WikiEducationFoundation/WikiEduDashboard/tree/wmflabs)** **[Phabricator Project](https://phabricator.wikimedia.org/project/manage/1052/)**  

### Infrastructure Overview
- **Toolforge Tool**: [wikiedudashboard](https://toolsadmin.wikimedia.org/tools/id/wikiedudashboard) 
   - **Source code: [WikiEduDashboardTools](https://github.com/WikiEducationFoundation/WikiEduDashboardTools)**: A collection of PHP endpoints that retrieve revision and article data from Wikimedia Replica databases in the Wikimedia Cloud environment.  
   - **Deployed at**: [wikiedudashboard.toolforge.org](https://wikiedudashboard.toolforge.org/), [replica-revision-tools.wmcloud.org](https://replica-revision-tools.wmcloud.org/)  

- **Cloud VPS Project**: [globaleducation](https://openstack-browser.toolforge.org/project/globaleducation)  

### Servers

1. **Web Server** 
   - **`peony-web.globaleducation.eqiad1.wikimedia.cloud`**  
     - Hosts the main web application and core Sidekiq processes using **RVM (Ruby Version Manager)**, **Phusion Passenger**, and **Apache**.
     - **Capistrano** is used for deployments  
     - Sidekiq processes hosted:  
       - `sidekiq-default`: Handles transactional jobs (e.g., wiki edits, email notifications).  
       - `sidekiq-constant`: Manages frequently run tasks (e.g., adding courses to update queues).  
       - `sidekiq-daily`: Executes long-running daily update tasks.  

2. **Sidekiq Servers**: These dedicated servers handle the other Sidekiq processes to isolate bottlenecks and failures:  
   - **`peony-sidekiq.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-short` for short-running course updates.  
   - **`peony-sidekiq-medium.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-medium` for typical course updates.  
   - **`peony-sidekiq-3.globaleducation.eqiad1.wikimedia.cloud`**: Hosts `sidekiq-long` for long-running course updates with higher queue latency.  

3. **Database Server**  
   - **`peony-database.globaleducation.eqiad1.wikimedia.cloud`**: Manages the Dashboard's primary database.  

4. **Redis Server**  
   - **`p-and-e-dashboard-redis.globaleducation.eqiad1.wikimedia.cloud`**: Shared across all Sidekiq processes for task queuing and caching.


## Monitoring and Logs

#### Toolforge
- [Kubernetes Namespace Details](https://k8s-status.toolforge.org/namespaces/tool-wikiedudashboard/)
- [Kubernetes Pod Details](https://k8s-status.toolforge.org/namespaces/tool-wikiedudashboard/pods/wikiedudashboard-5954f86c86-pm8d5/)


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

### Third-Party Dependencies
Issues could also be caused by maintenance or outages in third-party dependencies such as Openstack, Toolforge, or other services.


## More Resources
- [Toolforge Documentation](https://wikitech.wikimedia.org/wiki/Help:Toolforge)
- [Cloud VPS Documentation](https://wikitech.wikimedia.org/wiki/Help:Cloud_VPS)
- [Cloud VPS Admin Documentation](https://wikitech.wikimedia.org/wiki/Portal:Cloud_VPS/Admin)
- [Details of most recent P&E server update](https://github.com/WikiEducationFoundation/WikiEduDashboard/commit/df271f1c54fd0520e42445fcc88f19b6d03a603b#diff-f8eaa8feeef99c2b098e875ccdace93998b84eeb4110dc9f49b1327df7d96e21)
