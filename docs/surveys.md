# Surveys

The survey system is built from the RapidFire surveys rails engine, with a frontend that takes the HTML single-page surveys from RapidFire and uses jquery to build a one-question-at-a-time interface client-side.

To set up a survey, start from `/surveys` (also reachable from the `/admin` nav).
* Create a Question Group, then add Questions to it.
* Create a Survey, then add one or more Question Groups to it.
* Mark the Survey as "Survey Open (Anyone may take it)".
* Now you can view and take the survey via the 'Preview' link on the Surveys index. Remove `?preview` from the URL if you want to save a response in the database.

SurveyAssignment represents assigning a survey to a group of users, based on the Campaign(s) for the Course(s) they are in, along with their role (student, instructor). For example, you can create a survey assignment for students in Fall 2023 courses. An active SurveyAssignment gets rechecked via a periodic background job to see which users are newly eligible for the survey.

SurveyNotification represents assigning a survey to an individual user. When a SurveyAssignment gets checked, the system will create a SurveyNotification for any eligible user who doesn't already have one for that survey. The SurveyNotification will trigger a banner pointing to the survey whenever that user visits the course page, as well as a series of email reminders linking to the survey.