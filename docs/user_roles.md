## User accounts

The dashboard relies on Wikipedia for user accounts and authentication. To work
in your development environment, you will need a personal account on Wikipedia.

It can be useful to have two separate accounts, so that you can log in with them
simultaneously with two different browsers and test interactions between different
user roles, such as instructor and student.

If you don't already have one, you can create a Wikipedia account starting from
your dashboard development environment, by clicking Log In or Sign Up from the
home page.

NOTE: The dashboard is capable of making edits on Wikipedia using your account. This
will only happen if you have set up your own OAuth consumer; the default one
included in `application.example.yml` is not capable of making edits. Unless you
are working on features related to making Wikipedia edits, you won't need to worry
about this. If you are working on Wikipedia edits, be aware that live public edits
can be made on Wikipedia, and you are responsible for the content of them.

## Admin permissions

You probably want to give your main account admin permissions for the dashboard.
You can do so from the rails console:

- $ `rails c`
- > `User.find_by(username: '<your username').update_attribute(:permissions, 1)`

## Instructor role

To use the dashboard as an instructor, you can either use an account with admin
permissions, or use another account and select the 'instructor' option from the
onboarding process (http://localhost:3000/onboarding). Either way, you'll be able
to create new courses/programs after that from the home page.

## Creating a course/program

Click 'Create Course' from the home page and proceed from there. Once you've created
a course, you can Submit from the banner and then as an admin, you can approve it
by clicking 'Edit Details' on the course page, then adding it to a Campaign by
clicking the plus button next to 'Campaigns' and selecting one.

After it has been approved, you will see a notification that includes the enroll link.
This is the link — which includes a passcode — that you can use to join the course
as a student.

## Joining a course as a student

The same user cannot be both instructor and student in one course. If you are using
two different accounts, You can either use the instructor/admin account to add the student account
to the course:

* Go to the Students (Editors) tab
* Click Enrollment (Participation)
* Add the student's username and click Enroll (Add Editor)

... or you can visit the enroll URL (visible to the instructor) using the student account.

## Populating a course with data

The data for Articles, Activity, Uploads and so on for a course comes from activity
on Wikipedia by the participants. You can add active users on Wikipedia to pull in
arbitrary activity data.

1. Go to Wikipedia and find a recently-active editors, for example by picking some usernames from https://en.wikipedia.org/wiki/Special:RecentChanges
2. As an instructor or admin, go the Students tab, click Participation, and add them.
3. Run the 'constant_update' and 'daily_update' routines (which run via cron job in production) to pull in activity from those users.
    * $ `rake batch:update_constantly`
    * $ `rake batch:update_daily`

## Wiki Education configuration vs. Programs & Events configuration

The dashboard has two production deployments, which are configured differently.

The Wiki Education Dashboard (dashboard.wikiedu.org) is for Wiki Education,
and is built around the "Classroom Program" involving college students and instructors.
It is more locked down, required approval from an admin before a course can proceed.

The Wikimedia Programs & Events Dashboard (outreachdashboard.wmflabs.org) is for
the global Wikipedia/Wikimedia community, across many languages. With this configuration,
courses are by default called "Programs", and they are approved by default upon creation.

Some features are only enabled for one configuration or the other, and some of the
interface messages differ between them: Course vs. Program, Student vs. Editor, etc.
