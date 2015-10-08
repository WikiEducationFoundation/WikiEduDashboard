[Back to README](../README.md)

## Analytics Pipeline

#### Scheduled Tasks
- **`batch:update_constantly` (every 15 minutes):** Triggers a string of importers that update courses, users, revisions, articles, view counts for newly added articles, article ratings, and cached values
- **`batch:update_daily`: (at 4:30am server time)** Triggers a string of importers that update view counts, article ratings, article statuses, uploads, and cached values

#### Key Importers
- **[RevisionImporter](../lib/importers/revision_importer.rb):** Entry point for revision and article data from the WMFLabsTools-hosted WikiEduDashboardTools
- **[CourseImporter](../lib/importers/course_importer.rb):** Entry point for course, user, and assignment importing from the Wikipedia-based course pages plugin ***(this is deprecated as of Fall 2015, as the Dashboard provides course page functionality)***

#### APIs
- **stats.grok.se:** Source for all article and revision view counts
- **WMFLabsTools:** Source for all revision and article data except view counts
- **MediaWiki API:** Data about uploads to Wikimedia Commons, revision metadata, and user information. All or nearly all data from WMFLabsTools could be reimplemented to pull directly from MediaWiki, and we need to use MediaWiki directly when it is important to fetch up-to-date data, since the replica database used by WMFLabsTools may have replication lag.
- **MediaWiki EducationProgram extension:** The 'liststudents' API provided by this extension is the source for legacy course, user, and assignment data ***(this is depecreated as of Fall 2015, as the Dashboard provides course page functionality)***
