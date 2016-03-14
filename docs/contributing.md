[Back to README](../README.md)

## Contributing

We love contributions! If you're looking for a way to get involved, contact
Sage Ross (`ragesoss`).

#### Bugs and enhancement issues

The dashboard uses GitHub issues for bug tracking. Our main categories of bugs
organize problems by their importance (not how complex they will be to fix):
* [minor bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/minor%20bug) - These are bugs or usability problems that do not fundamentally break the dashboard user experience, or that only affect edge cases. It's great to fix these, but they won't necessarily be prioritized any time soon (if ever).
* [bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/bug) - These are bugs that should definitely be fixed. They may not require immediate attention, but they significantly affect some aspect of dashboard functionality.
* [high-importance bug](https://github.com/WikiEducationFoundation/WikiEduDashboard/labels/high-importance%20bug) - These are big problems. They should fixed as soon as possible.

Possible improvements that are not bugs per-se — mostly ones that are independent, rather than complex feature requests — are also tracked:
* [enhancement](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?utf8=%E2%9C%93&q=is%3Aissue+is%3Aopen+label%3Aenhancement) - User-facing improvements that address some usability or functionality need
* [code quality](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?q=is%3Aissue+is%3Aopen+label%3A%22code+quality%22) - Developer-facing improvements that make the dashboard easier to work with or otherwise improve the quality of the code-base.

If you're a new developer and you're looking for an easy way to get involved, try one of the bugs tagged as easy:
* [easy](https://github.com/WikiEducationFoundation/WikiEduDashboard/issues?q=is%3Aissue+is%3Aopen+label%3Aeasy) - These are probably fairly simple to fix, without needing to understand the entire application or make extensive changes.

#### Developer Resources

- [MediaWiki API Manual](https://www.mediawiki.org/wiki/Manual:Contents)
- [MediaWiki API Sandbox](https://en.wikipedia.org/wiki/Special%3aApiSandbox)
- [Quarry](http://quarry.wmflabs.org/): Public querying interface for the Labs replica database. Very useful for testing SQL queries and for figuring out what data is available.
- [Guide to the front end](frontend.md)
- [Vagrant](https://github.com/marxarelli/wikied-vagrant): a configuration to quickly get a development environment up and running using Vagrant. If you already have VirtualBox and/or Vagrant on your machine, this is probably the simplest way to set up a dev environment.

#### Code Style
This project adheres as strictly as possible to the community [Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide). [Rubocop](https://github.com/bbatsov/rubocop) is used for this purpose and its associated editor integrations are highly recommended for contributors.

#### Tests
Please see the more complete document on [testing](testing.md).

#### Translations
Copy translations live at /config/locales and the fallback for missing strings is `en`. [i18n.js](https://github.com/fnando/i18n-js) is used to make these translations available on the frontend. The JS files providing the translations to the front end must be regenerated whenever a change is made by running `rake i18n:js:export`.

To help translate the interface, please visit [translatewiki.net](https://translatewiki.net/wiki/Translating:Wiki_Ed_Dashboard).

## Pre-push checklist
- If you have added any external libraries via a package manager please ensure that you have updated the proper dependency list (`bower.json`, `package.json`, or `Gemfile`).

- If your changes modify the model schema please regenerate `erd.pdf`.

		$ rake erd orientation=vertical

- If your changes include copy changes please ensure that you are using the i18n pipeline and that you have regenerated the front-end i18n JS files.

		$ rake i18n:js:export

- If your changes modify the JS or CSS of the application (or if you have added external libraries via Bower or NPM) you must rebuild fingerprinted assets (for proper cache busting). This will add some gunk to your `git status`as the old assets will be deleted and the new assets must be added.

		$ gulp build
