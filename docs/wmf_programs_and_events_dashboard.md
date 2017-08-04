### Wikimedia Programs & Events Dashboard vs Wiki Education Dashboard

The Wiki Ed dashboard supports two main use cases: Wiki Education's
dashboard.wikiedu.org, and a general use, cross-language Programs & Events Dashboard
available for anyone to use with any Wikimedia project.

Some interface messages differ between the two use cases, and some features are
only enabled or intended for one use case. All new work should utilize feature
toggles (see the [Features presenter](../app/presenters/features.rb)) and should be rely on configuration
variables such that no new features specific to only one use case will be enabled
by default.

#### Wiki Ed-only features

As of June 2016:
* Surveys
* Training
* Wizard for creating new assignment timelines
* ClassroomProgramCourse & VisitingScholarship course types
* Course timelines, which are disabled for other course types
* "Get Help" button
* ask.wikiedu.org integration
* Wiki Education blog integration
