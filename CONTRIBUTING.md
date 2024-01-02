[Back to README](README.md)

## Contributing

We love contributions! If you're looking for a way to get involved, contact
Sage Ross (`ragesoss`). Our main venue for collaboration is Slack; ask Sage (sage at wikiedu.org) for an invite.

## Quick start guide

* Set up a dev environment. Follow the [setup docs](docs/setup.md). Try the automatic scripts, and report any problems that force you to use the manual instructions. For Windows, use WSL 2 (not RubyInstaller or RailsInstaller).
* Explore the issues, choose one to work on, and leave a comment. Work on only one issue at a time. We do not assign issues, but if it looks like someone else is working on one you are interested, give them a ping to ask if they are still active on it.
* Open a Pull Request. Mark it as a draft if you know it is not ready to merge. Small change sets are preferred; the fewer lines changed per PR, the easier it is to think about, provide feedback on, and review. Make sure only changes related to the main issure are included; unrelated changes can be made in a separate PR. Include before/after screenshots or videos, if applicable. If you have many commits, consider squashing them into one or a few commits with well-written commit messages.
* If you are stuck, ask on Slack.
* If you are here because you want to apply for Google Summer of Code or Outreachy, read the [this too](docs/students_and_interns.md).

## The repo and the code

#### Bugs and enhancement issues

The dashboard uses GitHub issues for bug tracking. Our main categories of bugs
organize problems by their importance (not how complex they will be to fix):
* [minor bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/minor%20bug) - These are bugs or usability problems that do not fundamentally break the dashboard user experience, or that only affect edge cases. It's great to fix these, but they won't necessarily be prioritized any time soon (if ever).
* [bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/bug) - These are bugs that should definitely be fixed. They may not require immediate attention, but they significantly affect some aspects of dashboard functionality.
* [high-importance bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/high-importance%20bug) - These are big problems. They should be fixed as soon as possible.

Possible improvements that are not bugs per-se — mostly ones that are independent, rather than complex feature requests — are also tracked:
* [enhancement](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3Aenhancement) - User-facing improvements that address some usability or functionality need
* [code quality](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?q=is%3Aissue+is%3Aopen+label%3A%22code+quality%22) - Developer-facing improvements that make the dashboard easier to work with or otherwise improve the quality of the code-base.

If you're a new developer and you're looking for an easy way to get involved, try one of the bugs tagged as newcomer friendly:
* [newcomer friendly](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?q=is%3Aissue+is%3Aopen+label%3A%22newcomer+friendly%22) - These range from very simple to moderately complex, but won't require you to understand the entire application or make extensive changes. We try to keep a few of these open for "microcontributions" for Outreachy applicants and others looking for an easy-to-intermediate task. If you can't find one you like, ask Sage!

#### Developer Resources

- [MediaWiki API Manual](https://www.mediawiki.org/wiki/Manual:Contents)
- [MediaWiki API Sandbox](https://en.wikipedia.org/wiki/Special%3aApiSandbox)
- [Quarry](http://quarry.wmflabs.org/): Public querying interface for the Labs replica database. Very useful for testing SQL queries and for figuring out what data is available.
- [Guide to the front end](docs/frontend.md)
- [Vagrant](https://github.com/marxarelli/wikied-vagrant): a configuration to quickly get a development environment up and running using Vagrant. If you already have VirtualBox and/or Vagrant on your machine, this might be a simple way to set up a dev environment. However, it is not actively maintained. If you try it and run into problems, let us know!

#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

The project has a mix of templating and compiled languages, including haml for Rails templates, and a mix of pure javascript and jsx for the frontend, and Stylus for stylesheets.

All javascript and jsx files must pass eslint.

#### Tests
Please see the more complete document on [testing](docs/testing.md). Pull requests should be passing for both the Ruby test suite (`rake spec`) and the javascript test suite (`npm test`). Ideally, pull requests should include new tests for any new features, as well.

#### Translations
Interface message translations live at /config/locales and the fallback for missing strings is `en`. [i18n.js](https://github.com/fnando/i18n-js) is used to make these translations available on the frontend. If you add a new interface message, you should add it to both `en.yml` (the default language) and `qqq.yml` (the message documentation file, to help translators understand the meaning and context of the message).

To help translate the interface, please visit [translatewiki.net](https://translatewiki.net/wiki/Translating:Wiki_Ed_Dashboard).

#### Schema changes
Migrations that change the schema should be as isolated as possible. If existing tables are being modified, each migration should change only one column. Data migrations should be done with separate migrations, rather than combined into the same migration as a schema change.

If your changes modify the model schema, please regenerate `erd.pdf` and regenerate the model schema annotations.

* $ `rake erd orientation=vertical`
* $ `annotate`

Also, ensure that the corresponding schema.rb changes only reflect the new migrations.

## Pull request process

### Before opening a PR
- Create a git branch for the issue you are working on, rather than working directly on `master`.
- Rebase your work onto the latest version from master and fix any merge conflicts. (See [git.md](docs/git.md) for common Git procedures.)
- Check that only the relevant files are being changed. There should be no unintended changes to the schema or dependency files, or other "git noise".
- If you have a messy git history, squash your commits to clean it up.
- If you have added any external libraries via a package manager, ensure that you have updated the proper dependency list (`package.json`, or `Gemfile`) and corresponding lock file.

### PR format
- Title your pull request to indicate its purpose. (This will likely be similar to the title of the issue it addresses.)
- Include a reference to the issue(s).
- If it is a work-in-progress, include `[WIP]` in the title. Remove this once the PR is complete and ready for review.
- Include before-and-after screenshots (or animations) for user interface changes.

### After opening a PR
- Check the travis-ci continuous integration build once it completes. This usually takes about 30 minutes, and if any tests fail you can find details in the build log.
- If the build failed:
  - Fix whatever caused it to fail if you can.
  - Ask for help if you cannot fix it. If a pull request build is failing but you have not asked for help, we will assume that you have seen the errors and are still working on them.
- If you don't get reviewer feedback within a day or two, or you're waiting for followup, ping someone.
