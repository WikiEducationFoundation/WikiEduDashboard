[Back to README](../README.md)

## Analytics Pipeline

#### Scheduled Tasks

Recurring tasks are managed by Sidekiq via the sidekiq-cron plugin. See `config/schedule.yml`.

#### Key Importers
- **[ArticleImporter](../lib/importers/article_importer.rb):** Imports articles based on mediawiki page id or title.
- **[UploadImporter](../lib/importers/upload_importer.rb):** Imports files uploaded to Wikimedia Commons.
- **[UserImporter](../lib/importers/user_importer.rb):** Imports user data.

Imported data is persisted in the database.

#### Extra Data Importers
- **[AverageViewsImporter](../lib/importers/average_views_importer.rb):** Updates average view counts for articles.
- **[RatingImporter](../lib/importers/rating_importer.rb):** Updates article ratings.

Imported data is persisted in the database.

#### Category Sources Importers
- **[CategoryImporter](../lib/importers/category_importer.rb):** Imports article titles from a specified category.
- **[PagePileApi](../lib/page_pile_api.rb):** Imports article titles from a pile id.
- **[PetScanApi](../lib/pet_scan_api.rb):** Imports article titles from a pet scan id.
- **[TransclusionImporter](../lib/importers/transclusion_importer.rb):** Imports article titles that transclude a given page.

Imported data is persisted in the database.

#### Revision Fetchers
Since the data-rearchitecture deployment, the Dashboard no longer stores data for each individual wiki
revision in the database. Instead, it collects data for revisions within a certain timeframe and stores only the aggregate
statistics for each time period (what we call *timeslices*).
- **[RevisionDataManager](../lib/revision_data_manager.rb):**  Fetches revisions and corresponding scores (it invokes the RevisionScoreImporter).
- **[RevisionScoreImporter](../lib/importers/revision_score_importer.rb):** Fetches revision scoring data from Lift Wing and reference-counter APIs.

#### APIs
- **WMFLabsTools:** Source for all revision and article data except view counts
- **MediaWiki API:** Data about uploads to Wikimedia Commons, revision metadata, and user information. All or nearly all data from WMFLabsTools could be reimplemented to pull directly from MediaWiki, and we need to use MediaWiki directly when it is important to fetch up-to-date data, since the replica database used by WMFLabsTools may have replication lag.
