## Before the Pull Request ##
* Test out your changes manually to confirm that it all works and search for bugs.
* Run the Javascript tests locally (`yarn test`) and confirm that they are passing.
* Run the specs for any Ruby files you changed, along with the feature specs that are related to your changes. Optionally, you can run the entire test suite locally (`rake spec`).

## Opening the Pull Request ##

* Describe the changes included in the PR.
* Note the issue that the PR addresses. Include `Fixes #12345` if it will completely address the issue.
* If there are UI elements to the change, include a screenshot or animation to illustrate it.
* If the PR is not complete but you want feedback on it or you just want to trigger a build, include `[WIP]` in the title to indicate work-in-progress, and add comments about anything you're stuck on. Edit the title when it's ready.

## After the PR ##
* Check the continuous integration build, which usually takes about 20 minutes.
    * Fix any failures.
    * Add a comment to the PR if you are stuck. If the build is failing and you don't discuss it with anyone, we will assume that you've seen the failing specs and are working to fix them.
    * Occasionally, specs unrelated to the PR will fail. If you think that's the case, you can ping someone to restart the build, or close and reopen the PR to trigger a new build.
* If the build is passing, we will review it as soon as we can.
* If you are abandoning a PR, please close it to help us keep track of which PRs are still active.
