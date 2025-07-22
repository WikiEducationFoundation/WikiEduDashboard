[Back to README](../README.md)

## Analytics Pipeline

#### Scheduled Tasks

Recurring tasks are managed by Sidekiq via the sidekiq-cron plugin. See `config/schedule.yml`.

#### Key Importers
- **[RevisionImporter](../lib/importers/revision_importer.rb):** Entry point for revision and article data from the WMFLabsTools-hosted WikiEduDashboardTools

#### APIs
- **WMFLabsTools:** Source for all revision and article data except view counts
- **MediaWiki API:** Data about uploads to Wikimedia Commons, revision metadata, and user information. All or nearly all data from WMFLabsTools could be reimplemented to pull directly from MediaWiki, and we need to use MediaWiki directly when it is important to fetch up-to-date data, since the replica database used by WMFLabsTools may have replication lag.
