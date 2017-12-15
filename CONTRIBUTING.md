[Back to README](README.md)

## Contributing

We love contributions! If you're looking for a way to get involved, contact
Sage Ross (`ragesoss`).
You can also join our [IRC Channel](https://webchat.freenode.net/?channels=#wikimedia-ed) ! 

#### Bugs and enhancement issues

The dashboard uses GitHub issues for bug tracking. Our main categories of bugs
organize problems by their importance (not how complex they will be to fix):
* [minor bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/minor%20bug) - These are bugs or usability problems that do not fundamentally break the dashboard user experience, or that only affect edge cases. It's great to fix these, but they won't necessarily be prioritized any time soon (if ever).
* [bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/bug) - These are bugs that should definitely be fixed. They may not require immediate attention, but they significantly affect some aspect of dashboard functionality.
* [high-importance bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/high-importance%20bug) - These are big problems. They should fixed as soon as possible.

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

The project has a mix of templating and compiled languages, including both erb and haml for Rails templates, and a mix of pure javascript and jsx for the frontend. We're trying to standardize on haml, javascript, and jsx for everything. **Please use haml, javascript, and/or jsx** for new files; erb, coffeescript, and cjsx are deprecated.

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

## Pull request checklist
- Rebase your branch on master if it is behind.
- Optionally, squash your work into a single commit.
- If you have added any external libraries via a package manager please ensure that you have updated the proper dependency list (`bower.json`, `package.json`, or `Gemfile`).
- After opening a PR, verify that the continuous integration tests pass; if not, add more commits to fix them.
