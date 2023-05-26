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

### Blocked users

A user who is blocked from editing Wikipedia may still log in to the Dashboard,
and the system can still attempt to make edits on their behalf; the edits that
fail due to a block are logged to Sentry.

## Admin permissions

You probably want to give your main account admin permissions for the dashboard.
You can do so from the rails console:

- $ `rails c`
- > `User.find_by(username: '<your username>').update_attribute(:permissions, 1)`

## Instructor role

To use the dashboard as an instructor, you can either use an account with admin
permissions, or use another account and select the 'instructor' option from the
onboarding process (http://localhost:3000/onboarding). Either way, you'll be able
to create new courses/programs after that from the home page.

## Assigning special roles

To assign users to special roles. Go to the `/settings` page in the dashboard (http://localhost:3000/settings). This will allow you to give users admin privileges and other special user permissions such as classroom program manager, technical help staff, Wikipedia expert and many others. Note that your account needs to have admin permissions to access the page (refer to [Admin permissions](#admin-permissions) for more information) 

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

## Populating initial courses

You can set up a few standard courses by running the following rake task:

```
rake dev:populate
```

Go to the **Explore** or **Find Programs** page to see the created campaigns and courses.


## Copy a course from production

You can create a copy of a course from production if you know its URL, like this:

```
rake dev:copy_course 'https://dashboard.wikiedu.org/courses/Southwestern_University/Biochemistry_(Fall)'
```

This will copy the title, dates, and participants. Running a data update will pull in stats for the course.

## Populating a course with data

The data for Articles, Activity, Uploads and so on for a course comes from activity
on Wikipedia by the participants. You can add active users on Wikipedia to pull in
arbitrary activity data.

To reproduce a working course with active editors, complete the following:

1. Go to Wikipedia and find the usernames of [recently active editors](https://en.wikipedia.org/wiki/Special:RecentChanges).
1. For populating the Uploads, find users [who have recently uploaded files](https://en.wikipedia.org/wiki/Special:Log/upload).
1. As an instructor or admin, create a course with dates _that encompass the dates of the changes_. For example, if the editor you're looking to add made changes on February 1st, 2019. Start your course in January and end it after February.
1. Then, go to the "Students" tab of the course and add those students. (Note: If you do not see the students tab, you may need to approve the course. You can do so by clicking "Edit Details" on the course's home page and adding it to a campaign.)
4. Import course data by triggering a manual update. Either add `/manual_update` to the end of the base course URL, or use a console to load the Course record (e.g., `course = Course.last`) and then run `UpdateCourseStats.new(course)`.
5. Optionally, load additional metadata by running a `ConstantUpdate` in a console:
    * `require "#{Rails.root}/lib/data_cycle/constant_update`
    * `ConstantUpdate.new`

## Wiki Education configuration vs. Programs & Events configuration

The dashboard has two production deployments, which are configured differently.

The Wiki Education Dashboard (dashboard.wikiedu.org) is for Wiki Education,
and is built around the "Wikipedia Student Program" involving college students and instructors.
It is more locked down, required approval from an admin before a course can proceed.

The Wikimedia Programs & Events Dashboard (outreachdashboard.wmflabs.org) is for
the global Wikipedia/Wikimedia community, across many languages. With this configuration,
courses are by default called "Programs", and they are approved by default upon creation.

Some features are only enabled for one configuration or the other, and some of the
interface messages differ between them: Course vs. Program, Student vs. Editor, etc.

In `config/application.yml`, use `wiki_education: true` or `wiki_education: false` to
toggle between these configurations.

## Loading training modules

In `wiki_education` mode, you can load the full set of training modules from .yml files by visiting `/reload_trainings?module=all`.

In non-`wiki_education` mode, training content is loaded from meta.wikimedia.org, along with translations (if available) for each slide. The default configuration will load the same training content as Programs & Events Dashboard users, but you can change the training library, module and slide index pages in `application.yml` to test with a different or smaller set of content. Because the translations can take a while to load, you probably want to load individual modules instead of all of them at once. For example, visiting `/reload_trainings?module=wikipedia-essentials` will load only the Wikipiedia Essentials module.