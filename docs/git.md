# Git workflow best practices

## Initial setup
1. Fork the main WikiEduDashboard repo
2. Clone this repo on your machine
3. Add the main repo as "upstream"
  * `git remote add upstream https://github.com/WikiEducationFoundation/WikiEduDashboard.git`

## Starting a new issue
1. Get the latest version of the project
  * `git fetch upstream`
  * `git checkout master`
  * `git pull upstream master`

2. Create a new branch starting from that newly updated main branch, and link it to your GitHub fork.
  * `git checkout -b MyNewIssue`
  * `git push --set-upstream origin MyNewIssue`

3. Make your changes, commit them, and push them to your fork
  * *make changes*
  * `git commit -a`
  * *write a good commit message*
  * `git push`

## Rebasing your branch
When there have been changes in the main repo that you want to get, the cleanest option is often to rebase your branch on top of the latest commits.

1. Get the latest commits and update your local master branch
  * `git fetch upstream`
  * `git checkout master`
  * `git pull upstream master`

2. Rebase your in-progress feature branch
  * `git checkout MyInProgressFeature`
  * `git rebase master`
  * `git push -f`

## Resetting a branch after you've messed it up
1. Make sure the isn't any work that you care about losing
2. Do a hard reset to the branch you want to restart from.
  * `git checkout MyMessedUpBranch`
  * `git reset --hard upstream/master`

## Adding a single commit from one branch to another branch
1. Find and copy the commit ID that you want to use
2. Cherry-pick that commit
  * `git checkout MyCleanBranch`
  * `git cherry-pick COMMIT_ID`
