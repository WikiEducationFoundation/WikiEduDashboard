[Back to README](../README.md)

## Background

This document outlines the process to be followed - for Agile Ventures members - in developing and
submitting a pull request for this project.  The same process is used
regardless of whether the pull request is for a feature, a bug or a chore.

We use Waffle as our story board for this project.  The waffle board for this
project is [here](https://waffle.io/WikiEducationFoundation/WikiEduDashboard).

Make sure you are added as a "collaborator" to the project - confirm with the AV coordinator if there is any question (post a message about this to the project
slack channel if unsure about who to contact).

## Process Outline

## Step 1: Update Waffle
When you are ready to start work on a story:

1. Assign the specific story that you will work on to yourself.  You can do this
from the "Assignees" pull-down list.
2. Move the issue to the ‘In Progress’ column

Note:
  - Please don’t assign yourself to more than one story at a time,
  unless you're blocked on another story and are waiting for resolution.
  - You should only assign yourself to stories in the 'Current sprint' column.  Those
  stories have been voted on (have points (size) assigned) and have been
  designated for work during the current sprint.

## Step 2: Update local repo development branch
Reason: Your **local repo** *master* branch needs to stay in sync with the **project repo** *master* branch.  This is because you want to have your feature branch (to be created below) to have the latest project code before you start adding code for the feature you’re working on.

    git checkout master
    git fetch upstream
    git merge upstream/master

You should not have merge conflicts in step 3, unless you’ve made changes to your local *master* branch directly (which you should not do).

## Step 3: Create the feature branch in your local and github repos
Reason: All of your development should occur in feature branches - ideally, one branch per Waffle ticket.  This keeps your local *master* branch clean (reflecting *upstream* master branch), allows you to abandon development approaches easily if required (e.g., simply delete the feature branch), and also allows you to maintain multiple work-in-process branches if you need to (e.g., work on a feature branch while also working on fixing a critical bug - each in its own branch).

1. Create a branch whose name contains the Waffle story number. For example, if you are going to work on story #78 (which is, say, a new feature for ‘forgot password’ management):

        git checkout -b forgot-password#78

    This both creates and checks out that branch in one command.  
    The feature name should provide a (short) description of the issue,
    and should include the story number.

2. Push the new branch to your github repo:

        git push -u origin forgot-password#78

## Step 4: Develop the Feature
Develop the code for your feature (or chore/bug) as usual.  You can make interim commits to your local repo if this is a particularly large feature that takes a lot of time.

When you have completed development, make your final commit to the feature branch in your local repo.

## Step 5: Update local repo **master** branch
Didn’t we just do this is step 2?  Yes, but we should do it again in case any commits have occurred to the *master* branch in the project repo since you performed step 1.

    git checkout master
    git fetch upstream
    git merge upstream/master

## Step 6: Rebase master changes into feature branch
Now, you will need to rebase changes from the local repo *master* branch into the feature branch.

Reason: This step will add changes to your feature branch that have already been applied to the project repo *master* branch.  The result is that when you deliver your feature (that is, create a Pull Request), those changes will not be (needlessly) included in that Pull Request.

    git checkout <feature-branch-name>
    git rebase master

Run all tests to confirm that any changes brought in by rebasing did not break anything.  If there are errors, fix those and repeat steps 5 and 6.

## Step 7: Push feature branch to your github repo
Reason: We will now push the feature branch code to github so that we can create a Pull Request against the project repo (in next step).

    git checkout <feature-branch-name>
    git push origin <feature-branch-name>

## Step 8: Create Pull Request (PR)
On the github website:

1. Go to your personal repo on Github
2. Select the *master* branch in the “Branch: “ pull-down menu
3. Click the “Compare” link

    On the next page, the “base fork” and “base” should be **WikiEducationFoundation/WikiEduDashboard** and **master**, respectively.

4. Confirm “head fork: is set to **\<username\>/WikiEduDashboard**
5. Set “compare: “ to your feature branch name (e.g. *forgot-password#78*)
6. Review the file changes that are shown and confirm that all is OK.
7. Fill out details of the pull request - title, description, etc.
8. Click “Create Pull Request”

This last step will kick off a CI (continuous integration) process that will configure a test environment, load your changes, run all code tests and perform other checks configured within the CI environment.  If any problems arise you will see those at the end of the CI run and will need to address those before the Pull Request can be merged into the project repo.

## Step 9: Set Waffle Status
Move the issue to the ‘Needs review’ column.
