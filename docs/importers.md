[Back to README](../README.md)

## Analytics Pipeline

#### Scheduled Tasks
- **`batch:update_constantly` (run frequently throughout the day):** Triggers a string of importers that update courses, users, revisions, articles, view counts for newly added articles, article ratings, and cached values.
- **`batch:update_daily`: (at 4:30am server time)** Triggers a string of importers that update view counts, article ratings, article statuses, uploads, and cached values

#### Key Importers
- **[RevisionImporter](../lib/importers/revision_importer.rb):** Entry point for revision and article data from the WMFLabsTools-hosted WikiEduDashboardTools

#### APIs
- **WMFLabsTools:** Source for all revision and article data except view counts
- **MediaWiki API:** Data about uploads to Wikimedia Commons, revision metadata, and user information. All or nearly all data from WMFLabsTools could be reimplemented to pull directly from MediaWiki, and we need to use MediaWiki directly when it is important to fetch up-to-date data, since the replica database used by WMFLabsTools may have replication lag.
